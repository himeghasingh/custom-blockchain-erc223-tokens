# Nim Board Game Implementation

## Project Overview

I have implemented the Nim board game using Solidity on the Ethereum blockchain. This project features the "misere" version of Nim, where the player who makes the last move loses. The implementation covers managing the game state, validating moves, and determining the winner based on a predefined set of rules.

## Features

- **Nim Contract**: This contract manages the overall game state, validates player moves, and determines the winner.
- **NimPlayer Interface**: Defines the essential methods that any player contract must implement to participate in the game.
- **TrackingNimPlayer**: A base contract designed to track game outcomes such as wins, losses, and faults. This serves as a foundation for testing and tracking player performance.
- **Boring1NimPlayer**: Implements a simple strategy for playing Nim. This player follows basic rules to decide moves, making it easy to test the game logic.

## Interfaces

### `NimPlayer`

- `function nextMove(uint256[] calldata piles) external returns (uint, uint256);`
  - Returns a pile number and quantity of items to remove based on the current pile configuration.
- `function Uwon() external payable;`
  - Called when the player wins, awarding the player their winnings.
- `function Ulost() external;`
  - Called when the player loses.
- `function UlostBadMove() external;`
  - Called when the player loses due to making an illegal move.

### `Nim`

- `function startMisere(NimPlayer a, NimPlayer b, uint256[] calldata piles) payable external;`
  - Starts a new game between two players with a specified initial pile configuration. The fee for the game is 0.001 ether, and the winner receives the remaining funds.

## Contracts

### `NimBoard`

This contract implements the `Nim` interface, handling game state management, move validation, and win/loss determination.

### `TrackingNimPlayer`

Tracks the number of wins, losses, and faults for each player. Implements the basic `NimPlayer` functions to facilitate testing.

### `Boring1NimPlayer`

A straightforward implementation of a Nim player:
- Removes all but one item from a pile if the pile has more than one item.
- If no piles have more than one item, removes all items from a non-empty pile.

## Testing

1. **Deploy Contracts**:
   - Deploy the `NimBoard` contract.
   - Deploy two instances of `Boring1NimPlayer`.

2. **Game Execution**:
   - Use `startMisere` on the `NimBoard` contract with the deployed player instances and initial pile configuration.

3. **Verify Results**:
   - Check that the game results (wins/losses) and contract balances are as expected.

4. **Automated Testing**:
   - Additional contracts can be created to automate and validate various game scenarios.

## Example Test Vectors

1. Deploy `NimBoard` and two `Boring1NimPlayer` contracts.
2. Execute `C.startMisere(A, B, [1,1])` with 0.002 ether.
   - Player A should win and have a balance of 0.001 ether.
   - Player B should lose.

3. Execute `C.startMisere(A, B, [1,2])`.
   - Both players should have 1 win and 1 loss each.

## Notes

This project serves as an introduction to Solidity, focusing on understanding state management and interfaces. The implementation is designed to provide a foundational understanding of how smart contracts can be used to build and manage a game on the Ethereum blockchain.


