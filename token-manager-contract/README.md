# Ethereum Tokens Implementation

## Project Overview

I have developed a set of smart contracts based on the ERC223 token standard. ERC223 is an enhancement of ERC20 tokens, addressing the issue of accidentally sending tokens to contracts that cannot handle them. The project includes a `TokenManager` contract for minting and redeeming tokens, and a `TokenHolder` contract for managing and transferring tokens.

## Features

- **ERC223 Token**: Implements the ERC223 token standard to ensure safe token transfers.
- **TokenManager Contract**: Manages the creation, minting, and melting of tokens. It operates at a fixed exchange rate and handles the conversion between tokens and Ether.
- **TokenHolder Contract**: Allows tokens to be held, made available for sale, and transferred between holders or back to the `TokenManager`.

## Contracts

### `TokenManager`

- **Functionality**: Manages the token lifecycle, including minting new tokens and redeeming tokens for Ether at a predefined exchange rate.
- **Key Functions**:
  - `mintTokens(address to, uint256 amount)`: Mints new tokens for the specified address.
  - `meltTokens(uint256 amount)`: Redeems tokens for Ether.
  - `buyFromCaller()`: Allows anyone to buy tokens from the `TokenManager`.

### `TokenHolder`

- **Functionality**: Manages tokens on behalf of users. Tokens can be put up for sale, sold to others, or transferred between holders.
- **Key Functions**:
  - `putUpForSale(uint256 amount)`: Makes a specified amount of tokens available for sale.
  - `sellToCaller()`: Allows users to purchase tokens from the holder.
  - `withdraw(uint256 amount, address to)`: Transfers tokens between holders or to an external address.
  - `remit(uint256 amount)`: Sells tokens back to the `TokenManager`.

## Implementation Details

1. **TokenHolder Contract**: Implements the `ITokenHolder` interface and provides functionality for managing token sales and transfers.
2. **TokenManager Contract**: Acts as both an ERC223 token and a token manager, handling the minting and redeeming of tokens. It maintains a fixed exchange rate for transactions.
3. **Helper Functions**: Additional helper functions are included to support token management and ensure proper transfer of tokens and Ether.

## Testing

- **Deployment**: Upload all `.sol` files into the Remix IDE for compilation and testing.
- **Token Transfer**: Ensure tokens can be moved between holders and the `TokenManager` as expected.
- **Sales and Redemption**: Test the sale of tokens via `putUpForSale` and `sellToCaller`, and redemption via `remit`.

## Notes

- Ensure all transactions and token transfers are validated with appropriate `require` statements.
- Contracts are designed to be competitive, so care must be taken to prevent unauthorized token transfers between entities.

This implementation provides a solid foundation for working with ERC223 tokens and understanding the nuances of token management and transfer within the Ethereum blockchain.


