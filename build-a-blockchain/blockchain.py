
import sys
from collections import defaultdict

assert sys.version_info >= (3, 6)
import hashlib
import pdb
import copy
import json
# pip3 install dill
import dill as serializer


class Output:
    """ This models a transaction output """

    def __init__(self, constraint=None, amount=0):
        """ constraint is a function that takes 1 argument which is a list of
            objects and returns True if the output can be spent.  For example:
            Allow spending without any constraints (the "satisfier" in the Input object can be anything)
            lambda x: True

            Allow spending if the spender can add to 100 (example: satisfier = [40,60]):
            lambda x: x[0] + x[1] == 100

            If the constraint function throws an exception, do not allow spending.
            For example, if the satisfier = ["a","b"] was passed to the previous constraint script

            If the constraint is None, then allow spending without constraint
            amount is the quantity of tokens associated with this output """
        self.constraint = constraint
        self.amount = amount


class Input:
    """ This models an input (what is being spent) to a blockchain transaction """

    def __init__(self, txHash, txIdx, satisfier):
        """ This input references a prior output by txHash and txIdx.
            txHash is therefore the prior transaction hash
            txIdx identifies which output in that prior transaction is being spent.  It is a 0-based index.
            satisfier is a list of objects that is be passed to the Output constraint script to prove that the output is spendable.
        """
        self.txHash = txHash
        self.txIdx = txIdx
        self.satisfier = satisfier


class Transaction:
    """ This is a blockchain transaction """

    def __init__(self, inputs=None, outputs=None, data=None):
        """ Initialize a transaction from the provided parameters.
            inputs is a list of Input objects that refer to unspent outputs.
            outputs is a list of Output objects.
            data is a byte array to let the transaction creator put some
            arbitrary info in their transaction.
        """
        self.inputs = inputs if inputs else []
        self.outputs = outputs if outputs else []
        self.data = data if data else b""

    def getHash(self):
        """Return this transaction's probabilistically unique identifier as a big-endian integer"""
        return int.from_bytes(hashlib.sha256(serializer.dumps((self.inputs, self.outputs, self.data))).digest(), "big")

    def getInputs(self):
        """ return a list of all inputs that are being spent """
        return self.inputs

    def getOutput(self, n):
        """ Return the output at a particular index """
        return self.outputs[n]

    def validateMint(self, maxCoinsToCreate):
        """ Validate a mint (coin creation) transaction.
            A coin creation transaction should have no inputs,
            and the sum of the coins it creates must be less than maxCoinsToCreate.
        """
        if self.inputs == [] and sum(output.amount for output in self.outputs) > maxCoinsToCreate:
            return False
        return True

    def validate(self, unspentOutputDict):
        """ Validate this transaction given a dictionary of unspent transaction outputs.
            unspentOutputDict is a dictionary of items of the following format: { (txHash, offset) : Output }
        """
        # Check if the inputs in self.inputs are valid values in the unspentOutputs dict and they satisfy the constraint
        for inputElement in self.inputs:
            if (inputElement.txHash, inputElement.txIdx) not in unspentOutputDict.keys():
                return False
            output = unspentOutputDict[(inputElement.txHash, inputElement.txIdx)]
            if not output.constraint(inputElement.satisfier):
                return False
        totalInputAmount = 0
        totalOutputAmount = 0
        #   Check if the spent amount is lesser than or equal to the input amount
        for inputElement in self.inputs:
            totalInputAmount += unspentOutputDict[(inputElement.txHash, inputElement.txIdx)].amount

        for outputElement in self.outputs:
            totalOutputAmount += outputElement.amount

        if totalOutputAmount > totalInputAmount and len(self.inputs) != 0:
            return False

        return True


class HashableMerkleTree:
    """ A merkle tree of hashable objects.

        If no transaction or leaf exists, use 32 bytes of 0.
        The list of objects that are passed must have a member function named
        .getHash() that returns the object's sha256 hash as an big endian integer.

        Your merkle tree must use sha256 as your hash algorithm and big endian
        conversion to integers so that the tree root is the same for everybody.
        This will make it easy to test.

        If a level has an odd number of elements, append a 0 value element.
        if the merkle tree has no elements, return 0.

    """

    def __init__(self, transactions=None):
        self.transactions = transactions if transactions else []

    def calcMerkleRoot(self):
        """ Calculate the merkle root of this tree."""
        if not self.transactions:
            return 0

        hashes = [tx.getHash() for tx in self.transactions]

        while len(hashes) > 1:
            if len(hashes) % 2 != 0:
                hashes.append(0)

            new_hashes = []
            for i in range(0, len(hashes), 2):
                left = hashes[i]
                right = hashes[i + 1]
                new_hashes.append(
                    int.from_bytes(hashlib.sha256(left.to_bytes(32, "big") + right.to_bytes(32, "big")).digest(),
                                   "big"))
            hashes = new_hashes

        return hashes[0]


class BlockContents:
    """ The contents of the block (merkle tree of transactions)
        This class isn't really needed.  I added it so the project could be cut into
        just the blockchain logic, and the blockchain + transaction logic.
    """

    def __init__(self):
        self.data = HashableMerkleTree()

    def setData(self, d):
        self.data = d

    def getData(self):
        return self.data

    def calcMerkleRoot(self):
        return self.data.calcMerkleRoot()

    def getTransactions(self):
        return self.data.transactions


class Block:
    """ This class should represent a blockchain block.
        It should have the normal fields needed in a block and also an instance of "BlockContents"
        where we will store a merkle tree of transactions.
    """

    def __init__(self):
        self.childNode = []
        self.contents = BlockContents()
        self.cumulativeWork = 0
        self.height = 0
        self.header = {
            'nonce': 0,
            'target': 0,
            'priorBlockHash': 0,
            'merkleRoot': self.contents.calcMerkleRoot()
        }

    def getContents(self):
        """ Return the Block content (a BlockContents object)"""
        return self.contents

    def setContents(self, data):
        """ set the contents of this block's merkle tree to the list of objects in the data parameter """
        self.contents.setData(HashableMerkleTree(data))

    def setTarget(self, target):
        """ Set the difficulty target of this block """
        self.header['target'] = target

    def getTarget(self):
        """ Return the difficulty target of this block """
        return self.header['target']

    def getHash(self):
        """ Calculate the hash of this block. Return as an integer """
        self.header['merkleRoot'] = self.contents.calcMerkleRoot()
        data = serializer.dumps((self.header, self.contents.getData()))
        return int.from_bytes(hashlib.sha256(data).digest(), 'big')

    def setPriorBlockHash(self, priorHash):
        """ Assign the parent block hash """
        self.header['priorBlockHash'] = priorHash

    def getPriorBlockHash(self):
        """ Return the parent block hash """
        return self.header['priorBlockHash']

    def mine(self, tgt):
        """Update the block header to the passed target (tgt) and then search for a nonce which produces a block who's hash is less than the passed target, "solving" the block"""
        self.header['target'] = tgt
        self.header['nonce'] = 0
        while self.getHash() >= tgt:
            self.header['nonce'] += 1

    def validate(self, unspentOutputs, maxMint):
        """ Given a dictionary of unspent outputs, and the maximum amount of
            coins that this block can create, determine whether this block is valid.
            Valid blocks satisfy the POW puzzle, have a valid coinbase tx, and have valid transactions (if any exist).

            Return None if the block is invalid.

            Return something else if the block is valid

            661 hint: you may want to return a new unspent output object (UTXO set) with the transactions in this
            block applied, for your own use when implementing other APIs.

            461: you can ignore the unspentOutputs field (just pass {} when calling this function)
        """

        assert isinstance(unspentOutputs,
                          dict), "unspent outputs should be a dictionary of tuples (hash, index) -> Output"
        # Return None if the hash is greater than or equal to the target
        if self.getHash() >= self.getTarget():
            return None

        transactions = self.contents.getTransactions()
        # Return the same unspent outputs if there are no transactions present
        if not transactions:
            return unspentOutputs
        # Check if the coinbase transaction is the first transaction and if it is within the valid minting amount
        coinbase_tx = transactions[0]
        if len(coinbase_tx.getInputs()) != 0:
            return None
        elif not coinbase_tx.validateMint(maxMint):
            return None
        # Return None if there are more than 1 coinbase transactions
        if sum(1 for tx in transactions if len(tx.getInputs()) == 0) > 1:
            return None

        new_unspent_outputs = copy.deepcopy(unspentOutputs)
        # Validate all transactions in the block and return the updated unspentOutputs
        for tx in transactions:
            if not tx.validate(new_unspent_outputs):
                return None

            for inputElement in tx.inputs:
                del new_unspent_outputs[(inputElement.txHash, inputElement.txIdx)]
            for idx, output in enumerate(tx.outputs):
                new_unspent_outputs[(tx.getHash(), idx)] = output

        return new_unspent_outputs


class Blockchain:
    def __init__(self, genesisTarget, maxMintCoinsPerTx):
        """ Initialize a new blockchain and create a genesis block.
            genesisTarget is the difficulty target of the genesis block (that you should create as part of this initialization).
            maxMintCoinsPerTx is a consensus parameter -- don't let any block into the chain that creates more coins than this!
        """
        self.blocks = defaultdict(Block)
        self.genesisTarget = genesisTarget
        self.maxMintCoinsPerTx = maxMintCoinsPerTx

        self.genesisBlock = Block()
        self.genesisBlock.setTarget(genesisTarget)
        self.genesisBlock.work = 1
        self.genesisBlock.cumulativeWork = 1
        self.genesisBlock.mine(self.genesisTarget)

        self.blocks[self.genesisBlock.getHash()] = self.genesisBlock

        self.maxHeight = 0
        self.tips = []
        self.tip = self.genesisBlock
        self.tips.append(self.tip)
        self.unspentOutputs = {self.genesisBlock.getHash(): {}}

    def getTip(self):
        """ Return the block at the tip (end) of the blockchain fork that has the largest amount of work"""
        # Calculate the tip with the maximum work done by checking which tip has the maximum cumulative work done
        pow = 0
        for tipElement in self.tips:
            if tipElement.cumulativeWork > pow:
                pow = tipElement.cumulativeWork
                self.tip = tipElement
        return self.tip

    def getWork(self, target):
        """Get the "work" needed for this target.  Work is the ratio of the genesis target to the passed target"""
        return self.genesisTarget / target

    def getCumulativeWork(self, blkHash):
        """Return the cumulative work for the block identified by the passed hash.  Return None if the block is not in the blockchain"""
        if blkHash in self.blocks:
            return self.blocks[blkHash].cumulativeWork
        else:
            return None

    def getBlocksAtHeight(self, height):
        """Return an array of all blocks in the blockchain at the passed height (including all forks)"""
        blocksAtHeight = []
        for block in self.blocks.values():
            if block.height == height:
                blocksAtHeight.append(block)
        return blocksAtHeight

    def extend(self, block):
        """Adds this block into the blockchain in the proper location, if it is valid.  The "proper location" may not be the tip!

            Hint: Note that this means that you must validate transactions for a block that forks off of any position in the blockchain.
            The easiest way to do this is to remember the UTXO set state for every block, not just the tip.
            For space efficiency "real" blockchains only retain a single UTXO state (the tip).  This means that during a blockchain reorganization
            they must travel backwards up the fork to the common block, "undoing" all transaction state changes to the UTXO, and then back down
            the new fork.  For this assignment, don't implement this detail, just retain the UTXO state for every block
            so you can easily "hop" between tips.

            Return false if the block is invalid (breaks any miner constraints), and do not add it to the blockchain.
        """
        # Check if the prior block hash mentioned in the block exists, and the block is not pretending to be  another genesis block
        if block.header['priorBlockHash'] not in self.blocks or block.header['priorBlockHash'] is None:
            return False
        priorBlock = self.blocks[block.header['priorBlockHash']]

        # Check if block.validate contains a valid set of transactions and the block is not None
        if type(block.validate(self.unspentOutputs[priorBlock.getHash()], self.maxMintCoinsPerTx)) != dict:
            return False
        if block is None:
            return False

        # We maintain a separate dict of unspentOutputs for each block and now that we know the block is valid, we want the updated unspentOutputs for this newly added block

        self.unspentOutputs[block.getHash()] = block.validate(self.unspentOutputs[priorBlock.getHash()],
                                                              self.maxMintCoinsPerTx)

        # We then mine the block and update the height, calculate the cumulative work
        block.mine(block.getTarget())
        self.blocks[block.getHash()] = block
        block.height = priorBlock.height + 1
        if self.maxHeight < block.height:
            self.maxHeight = block.height
        block.cumulativeWork = priorBlock.cumulativeWork + self.getWork(block.getTarget())
        # We maintain an array to store the tips of each branch. If the block is added to an already existing tip, we update the tip, if not, we create a new tip.
        if priorBlock in self.tips:
            self.tips[self.tips.index(priorBlock)] = block
        else:
            self.tips.append(block)
        return True

    # --------------------------------------------
    # You should make a bunch of your own tests before wasting time submitting stuff to gradescope.
    # Its a LOT faster to test locally.  Try to write a test for every API and think about weird cases.

    # Let me get you started:
    def Test(self):
        # test creating blocks, mining them, and verify that mining with a lower target results in a lower hash
        b1 = Block()
        b1.mine(int("F" * 64, 16))
        h1 = b1.getHash()
        b2 = Block()
        b2.mine(int("F" * 63, 16))
        h2 = b2.getHash()
        assert h2 < h1

        t0 = Transaction(None, [Output(lambda x: True, 100)])
        # Negative test: minted too many coins
        assert t0.validateMint(50) == False, "1 output: tx minted too many coins"
        # Positive test: minted the right number of coins
        assert t0.validateMint(50) == False, "1 output: tx minted too many coins"

        class GivesHash:
            def __init__(self, hash):
                self.hash = hash

            def getHash(self):
                return self.hash

        assert HashableMerkleTree([GivesHash(x) for x in [
            106874969902263813231722716312951672277654786095989753245644957127312510061509]]).calcMerkleRoot().to_bytes(
            32, "big").hex() == "ec4916dd28fc4c10d78e287ca5d9cc51ee1ae73cbfde08c6b37324cbfaac8bc5"

        assert HashableMerkleTree([GivesHash(x) for x in
                                   [106874969902263813231722716312951672277654786095989753245644957127312510061509,
                                    66221123338548294768926909213040317907064779196821799240800307624498097778386,
                                    98188062817386391176748233602659695679763360599522475501622752979264247167302]]).calcMerkleRoot().to_bytes(
            32, "big").hex() == "ea670d796aa1f950025c4d9e7caf6b92a5c56ebeb37b95b072ca92bc99011c20"

        print("yay local tests passed")
