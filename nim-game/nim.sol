// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface NimPlayer {
    function nextMove(uint256[] calldata piles) external returns (uint, uint256);
    function Uwon() external payable;
    function Ulost() external;
    function UlostBadMove() external;
}

interface Nim {
    function startMisere(NimPlayer a, NimPlayer b, uint256[] calldata piles) payable external;  
}

contract NimBoard is Nim {
    uint256[] public pileSizes;
    uint256 public totalAward;
    bool public gameOver;

    function startMisere(NimPlayer a, NimPlayer b, uint256[] calldata piles) payable external override {
        require(msg.value >= 0.001 ether, "Insufficient funds");

        totalAward = msg.value - 0.001 ether;
        gameOver = false;
        pileSizes = piles;
        //Until the game is over, both players play their turns
        while (!gameOver) {
            playTurn(a,b);
            //After the first turn, we again check if the game is now over
            if (gameOver) break;
            playTurn(b,a);
        }

    }

    function playTurn(NimPlayer player, NimPlayer opponent) internal {
        (uint pileIndex, uint256 itemsToRemove) = player.nextMove(pileSizes);
        //If the move made qualifies as an invalid move, game is over
        if (!isValidMove(pileIndex, itemsToRemove)) {
            gameOver = true;
            opponent.Uwon{value: totalAward}();
            player.UlostBadMove();
            return;
        }
        //If it is a valid move, we remove the requested number of items from the pile
        pileSizes[pileIndex] -= itemsToRemove;

        //We check if the game is over, after the latest move
        if (isGameOver()) {
            gameOver = true;
            opponent.Uwon{value: totalAward}();
            player.Ulost();
        }
    }

    function isGameOver() internal view returns (bool) {
        //Game is over when all piles are empty
        for (uint256 i = 0; i < pileSizes.length; i++) {
            if (pileSizes[i] > 0) {
                return false;
            }
        }
        return true;
    }

    function isValidMove(uint256 pileIndex, uint256 itemsToRemove) internal view returns (bool) {
        //A move is valid if atleast 1 item was removed from an existing pile and the number of items removed was less than or equal to the pile size at that index
        return itemsToRemove > 0 && pileIndex < pileSizes.length && pileSizes[pileIndex] >= itemsToRemove;
    }
}

contract TrackingNimPlayer is NimPlayer {
    uint losses=0;
    uint wins=0;
    uint faults=0;

    fallback() external payable {}
    receive() external payable {}

    function nextMove(uint256[] calldata) virtual override external pure returns (uint, uint256) {
        return (0, 1);
    }

    function Uwon() override external payable {
        wins += 1;
    }

    function Ulost() override external {
        losses += 1;
    }

    function UlostBadMove() override external {
        faults += 1;
    }

    function results() external view returns(uint, uint, uint, uint) {
        return (wins, losses, faults, address(this).balance);
    }
}

contract Boring1NimPlayer is TrackingNimPlayer {
    function nextMove(uint256[] calldata piles) override external pure returns (uint, uint256) {
        for(uint i = 0; i < piles.length; i++) {
            if (piles[i] > 1) return (i, piles[i] - 1);
        }
        for(uint i = 0; i < piles.length; i++) {
            if (piles[i] > 0) return (i, piles[i]);
        }
        return (0, 0);
    }
}


// contract NimGameTester {
//     NimBoard nimGame;
//     TrackingNimPlayer A;
//     TrackingNimPlayer B;

//     constructor() {
//         nimGame = new NimBoard();
//         A = new TrackingNimPlayer();
//         B = new TrackingNimPlayer();
//     }

//     // Game with pile sizes [1, 1]
//     function testGame1() external {
//         uint256[] memory pileArray = new uint256[](2);
//         pileArray[0] = 1;
//         pileArray[1] = 1;
//         nimGame.startMisere{value: 0.002 ether}(A, B, pileArray);

//         require(A.wins() == 1, "FAIL: A should have 1 win");
//         require(B.losses() == 1, "FAIL: B should have 1 loss");
//         require(address(A).balance == 1000000000000000, "FAIL: A balance mismatch");
//         require(address(B).balance == 0, "FAIL: B balance incorrect");

//     }

//     // Game with pile sizes [1, 2]
//     function testGame2() external {
//         uint256[] memory pileArray = new uint256[](2);
//         pileArray[0] = 1;
//         pileArray[1] = 2;
//         nimGame.startMisere{value: 0.002 ether}(A, B, pileArray);

//         require(A.wins() == 1, "FAIL: A should have 1 win");
//         require(A.losses() == 0, "FAIL: A should have 0 losses");
//         require(B.wins() == 1, "FAIL: B should have 1 win");
//         require(B.losses() == 1, "FAIL: B should have 1 loss");
//         require(address(B).balance > 0, "FAIL: B balance incorrect");

//     }

//     //Game with insufficient funds
//     function testGame3() external {
    
//         uint256[] memory pileArray = new uint256[](2);
//         pileArray[0] = 1;
//         pileArray[1] = 1;

//         (bool valid, ) = address(nimGame).call{value: 0.00001 ether}(abi.encodeWithSelector(nimGame.startMisere.selector, A, B, pileArray));
//         require(!valid, "FAIL: Insufficient Funds");
//     }

//     //Game with removing negative number of items
//     function testGame4() external {
//         uint256[] memory pileArray = new uint256[](2);
//         pileArray[0] = 2;
//         pileArray[1] = 3;
//         TrackingNimPlayer invalidA = new TrackingNimPlayer();

//         invalidA.nextMove{value: 0.002 ether} = function(uint256[] memory) external pure returns (uint, uint256) {
//             return (0, uint256(-1));
//         };
//         nimGame.startMisere{value: 0.002 ether}(invalidA, B, pileArray);
//         require(nimGame.isGameOver(), "FAIL: Game is not over");
//         require(B.wins() == 1, "FAIL: B should have 1 win");
//         require(invalidA.faults() == 1, "FAIL: Invalid A should have 1 fault");
        
//     }

//     // Game with empty piles, pile sizes [0,0]
//     function testGame5() external {
//         uint256[] memory pileArray = new uint256[](2);
//         pileArray[0] = 0;
//         pileArray[1] = 0;

//         nimGame.startMisere{value: 0.002 ether}(A, B, pileArray);
//         require(nimGame.isGameOver(), "FAIL: Game should instantly get over");
//         require(A.wins() == 0, "FAIL: A should have 0 wins");
//         require(B.wins() == 0, "FAIL: B should have 0 wins");
//         require(A.losses() == 0, "FAIL: A should have 0 losses");
//         require(B.losses() == 0, "FAIL: B should have 0 losses");
//         require(A.faults() == 0, "FAIL: A should have 0 faults");
//         require(B.faults() == 0, "FAIL: B should have 0 faults");
//     }

//     // Game with removing more items than available 
//     function testGame6() external {
//         uint256[] memory pileArray = new uint256[](2);
//         pileArray[0] = 2;
//         pileArray[1] = 3;

//         nimGame.startMisere{value: 0.002 ether}(A, B, pileArray);
//         A.nextMove{value: 0.002 ether} = function(uint256[] memory) external pure returns (uint, uint256) {
//             return (0, pileArray[0] + 1);
//         };
//         require(nimGame.isGameOver(), "FAIL: Game is not over");   
//         require(A.faults() == 1, "FAIL: A should have 1 fault");
//         require(B.wins() == 1, "FAIL: B should have 1 win");
//     }
// }