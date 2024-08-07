# Blockchain Framework Implementation

## Overview

In this project, I extended and implemented a blockchain framework that integrates proof-of-work, transactions, blocks, and blockchain structures. The framework adheres to custom consensus rules tailored for streamlined testing and functionality.

## Key Features

### Consensus Rules

1. **No Difficulty Adjustment**: The blockchain operates without a difficulty adjustment algorithm. This design choice allows for straightforward handling of blocks with varying difficulties and discovering the most-work tip effectively.
2. **Block Validity**: Blocks without transactions (i.e., no coinbase transactions) are considered valid. This simplifies the testing process by isolating different aspects of block validation.
3. **Coinbase Transaction Requirement**: Blocks containing transactions are required to have the first transaction as the coinbase transaction. This ensures the proper inclusion of coinbase transactions in transaction-filled blocks.

### Block Merkle Tree

1. **Hashing**: Implemented SHA-256 hashing for all Merkle tree operations.
2. **Padding**: Applied padding with 0 to handle odd Merkle tree levels when necessary, ensuring the correct structure of the Merkle tree.

### Transactions

1. **Minting Transactions**: Implemented valid mint (coinbase) transactions with no inputs, adhering to the per-block "minting" maximum to control the creation of new coins.
2. **Spending Transactions**: For transactions that are not coinbase transactions, ensured that coins are not created. The total value of inputs must be greater than or equal to the total value of outputs.
3. **Constraint Scripts**: Developed constraint scripts as Python lambda expressions to manage permission for spending. These scripts accept a list of parameters and return `True` to grant permission. Transactions are rejected if the script execution fails or returns anything other than `True`.

### Additional Details

1. **Transaction Validation**: Assumed all submitted transactions are correct. Implemented the `Transaction.validate()` function to return `True` without managing the UTXO (unspent transaction outputs) set.
2. **Transaction Verification**: Verified transactions, including their constraint and satisfier scripts, and tracked the UTXO set to ensure accurate transaction processing.

## Libraries and Tools

- **`hashlib.sha256()`**: Used for SHA-256 hashing in Python.
- **Integer Conversion**: Converted SHA-256 byte arrays to big-endian integers with `int.from_bytes(bunchOfBytes, "big")`.
- **`dill` Library**: Utilized the `dill` library for serializing objects and Python lambda functions, which was essential for calculating transaction IDs.

This implementation provides a functional blockchain framework with custom rules and enhancements for streamlined testing and operation.
