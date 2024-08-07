// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IERC223.sol";
import "./ERC223.sol";
import "./ownable.sol";

abstract contract ITokenHolder is IERC223Recipient, Ownable
{
    using SafeMath for uint256;
    IERC223 public currency;
    uint256 public pricePer;  // In wei
    uint256 public amtForSale;

    // Return the current balance of ethereum held by this contract
    function ethBalance()  view external returns (uint)
    {
        return address(this).balance;
    }

    // Return the quantity of tokens held by this contract
    function tokenBalance() virtual external view returns(uint);

    // indicate that this contract has tokens for sale at some price, so buyFromMe will be successful
    function putUpForSale(uint /*amt*/, uint /*price*/) virtual public
    {
        assert(false);
    }

    // This function is called by the buyer to pay in ETH and receive tokens.  Note that this contract should ONLY sell the amount of tokens at the price specified by putUpForSale!
    function sellToCaller(address /*to*/, uint /*qty*/) virtual external payable
    {
        assert(false);
    }


    // buy tokens from another holder.  This is OPTIONALLY payable.  The caller can provide the purchase ETH, or expect that the contract already holds it.
    function buy(uint /*amt*/, uint /*maxPricePer*/, TokenHolder /*seller*/) virtual public payable onlyOwner
    {
        assert(false);
    }

    // Owner can send tokens
    function withdraw(address /*_to*/, uint /*amount*/) virtual public onlyOwner
    {
        assert(false);
    }

    // Sell my tokens back to the token manager
    function remit(uint /*amt*/, uint /*_pricePer*/, TokenManager /*mgr*/) virtual public onlyOwner payable
    {
        assert(false);
    }

    // Validate that this contract can handle tokens of this type
    // You need to define this function in your derived classes, but it is already specified in IERC223Recipient
    // function tokenFallback(address _from, uint /*_value*/, bytes memory /*_data*/) override external

}

contract TokenHolder is ITokenHolder
{   // Implement all ITokenHolder functions and tokenFallback

    // event Log(string info);
    // event LogUint(string key, uint256 value);
    // event TokenReceived(address indexed from, uint value, bytes data);
    using SafeMath for uint256;

    constructor(IERC223 _cur)
    {
        currency = _cur;
    }

    // function ethBalance() external view override returns (uint) {
    //     return address(this).balance;
    // }

    function tokenBalance() override virtual external view returns(uint) {
        return currency.balanceOf(address(this));
    }

    function putUpForSale(uint _amt, uint _price) virtual override public  {
        amtForSale = _amt;
        pricePer = _price;
    }

    function sellToCaller(address _to, uint _qty) virtual override external payable {
        require(_qty > 0, "Quantity must be greater than zero");
        require(amtForSale > 0, "Amount for Sale must be greater than zero");
        require(_qty <= amtForSale, "Insufficient tokens to selltokenholder");

        uint256 totalAmount = _qty*pricePer;
        require(msg.value >= totalAmount, "Incorrect payment amount");

        amtForSale -= _qty;
        currency.transfer(_to, _qty);
}

    function buy(uint _amt, uint _maxPricePer, TokenHolder _seller) virtual override public payable onlyOwner {
        uint sellerPrice = uint(_seller.pricePer());
        require(sellerPrice <= _maxPricePer , "Max Price is lower than seller price");

        // require(msg.value >= _amt * _maxPricePer, "Insufficient payment");
        // require(_amt <= _seller.amtForSale(), "Insufficient tokens to make this sale");

        uint prevBalance = currency.balanceOf(address(this));
        _seller.sellToCaller{value: sellerPrice*_amt}(address(this), _amt);

        require(currency.balanceOf(address(this)) >= prevBalance + _amt, "Transfer failed");

    }

    function withdraw(address _to, uint _amount) virtual override public onlyOwner {
        currency.transfer(_to, _amount);
    }

    function remit(uint _amt, uint _pricePer, TokenManager _mgr) virtual override public onlyOwner payable {
        // require(_amt <= currency.balanceOf(address(this)), "Insufficient tokens to remit");
        // require(msg.value == _amt * _pricePer, "Incorrect payment amount");
        // require(amtForSale == 0, "Tokens are still available for sale");

        putUpForSale(_amt, _pricePer);
        _mgr.buyFromCaller{value: _mgr.fee(_amt)}(_amt);
    }

    function tokenFallback(address /*_from*/, uint /*_value*/, bytes calldata /*_data*/) override view external {
        require (msg.sender == address(currency), "Incompatible");
    }

}


contract TokenManager is ERC223Token, TokenHolder
{
    // Implement all functions

    // Pass the price per token (the specified exchange rate), and the fee per token to
    // set up the manager's buy/sell activity
    uint256 public feePer = 0;
    using SafeMath for uint256;


    constructor(uint _price, uint _fee) TokenHolder(this) payable
    {
        pricePer = _price;
        feePer = _fee;
    }

    // Returns the total price for the passed quantity of tokens
    function price(uint amt) public view returns(uint)
    {
        return amt * pricePer;
    }

    // Returns the total fee, given this quantity of tokens
    function fee(uint amt) public view returns(uint)
    {
        return amt * feePer;
    }

    // Caller buys tokens from this contract
    function sellToCaller(address to, uint amount) payable override public {
        uint totalAmount = price(amount) + fee(amount);
        require(amount > 0, "Quantity must be greater than zero");
        require(msg.value >= totalAmount, "Insufficient payment");
        // require(amount <= balances[owner], "Insufficient tokens to selltokenmgr");
        ERC223Token ercHelper = ERC223Token(this);
        if(amount>=balanceOf(address(this)))
        {
            mint(amount);
        }
        ercHelper.transfer(to, amount);
    }


    // Caller sells tokens to this contract

    function buyFromCaller(uint amount) public payable
    {
        // uint totalAmount = price(amount) + fee(amount);
        require(amount > 0, "Quantity must be greater than zero");
        require(msg.value >= fee(amount), "Incorrect fee");
        uint prevBalance = balanceOf(address(this));
        // require(amount <= balances[msg.sender], "Insufficient tokens to sell");
        TokenHolder thold = TokenHolder(msg.sender);
        thold.sellToCaller{value: (price(amount))}(address(this), amount);

        require(balanceOf(address(this)) >= prevBalance + amount, "Transfer failed");
    }


    // Create some new tokens, and give them to this TokenManager
    function mint(uint amount) internal onlyOwner
    {
        _totalSupply = _totalSupply.add(amount);
        balances[address(this)] = balances[address(this)].add(amount);
    }

    // Destroy some existing tokens, that are owned by this TokenManager
    function melt(uint amount) external onlyOwner
    {
        require(balanceOf(address(this)) >= amount, "Insufficient balance");
        _totalSupply = _totalSupply.sub(amount);
        balances[address(this)] = balances[address(this)].sub(amount);
    }
}

// contract AATest
// {
//     event Log(string info);

//     function TestBuyRemit() payable public returns (uint)
//     {
//         emit Log("trying TestBuyRemit");
//         TokenManager tok1 = new TokenManager(100,1);
//         TokenHolder h1 = new TokenHolder(tok1);

//         uint amt = 2;
//         tok1.sellToCaller{value:tok1.price(amt) + tok1.fee(amt)}(address(h1),amt);
//         assert(tok1.balanceOf(address(h1)) == amt);

//         h1.remit{value:tok1.fee(amt)}(1,50,tok1);
//         assert(tok1.balanceOf(address(h1)) == 1);
//         assert(tok1.balanceOf(address(tok1)) == 1);

//         return tok1.price(1);
//     }

//     function FailBuyBadFee() payable public
//     {
//         TokenManager tok1 = new TokenManager(100,1);
//         TokenHolder h1 = new TokenHolder(tok1);

//         uint amt = 2;
//         tok1.sellToCaller{value:1}(address(h1),amt);
//         assert(tok1.balanceOf(address(h1)) == 2);
//     }

//    function FailRemitBadFee() payable public
//     {
//         TokenManager tok1 = new TokenManager(100,1);
//         TokenHolder h1 = new TokenHolder(tok1);

//         uint amt = 2;
//         tok1.sellToCaller{value:tok1.price(amt) + tok1.fee(amt)}(address(h1),amt);
//         assert(tok1.balanceOf(address(h1)) == amt);
//         emit Log("buy complete");

//         h1.remit{value:tok1.fee(amt-1)}(2,50,tok1);
//     }

//     function TestHolderTransfer() payable public
//     {
//         TokenManager tok1 = new TokenManager(100,1);
//         TokenHolder h1 = new TokenHolder(tok1);
//         TokenHolder h2 = new TokenHolder(tok1);

//         uint amt = 2;
//         tok1.sellToCaller{value:tok1.price(amt) + tok1.fee(amt)}(address(h1),amt);
//         assert(tok1.balanceOf(address(h1)) == amt);

//         h1.putUpForSale(2, 200);
//         h2.buy{value:2*202}(1,202,h1);
//         h2.buy(1,202,h1);  // Since I loaded money the first time, its still there now.
//     }

//     // Buy failed due to insufficent fee
//     function FailBuyInsufficentFee() payable public
//     {
//         TokenManager tok1 = new TokenManager(100, 1);
//         TokenHolder h1 = new TokenHolder(tok1);

//         uint amt = 2;
//         tok1.sellToCaller{value: tok1.price(amt) + tok1.fee(amt-1)}(address(h1), amt);
//         assert(tok1.balanceOf(address(h1)) == 0);
//     }

//     // Transfer failed due to transfer of more tokens than available in TokenHolder
//     function ExcessTransferFail() payable public {
//         TokenManager tok1 = new TokenManager(100, 1);
//         TokenHolder h1 = new TokenHolder(tok1);
//         TokenHolder h2 = new TokenHolder(tok1);

//         uint amt = 2;
//         tok1.sellToCaller{value: tok1.price(amt) + tok1.fee(amt)}(address(h1), amt);
//         assert(tok1.balanceOf(address(h1)) == amt);

//         h1.putUpForSale(2, 10);
//         h2.buy{value: 4 * 20}(4, 20, h1);
//         h2.buy(4, 20, h1);
//         assert(tok1.balanceOf(address(h1)) == amt);

//     }

//     // Buy failed due to insufficent price amount
//     function FailBuyInsufficientPayment() payable public {
//         TokenManager tok1 = new TokenManager(100, 1);
//         TokenHolder h1 = new TokenHolder(tok1);

//         uint amt = 2;
//         tok1.sellToCaller{value: tok1.price(amt-1) + tok1.fee(amt)}(address(h1), amt);
//         assert(tok1.balanceOf(address(h1)) == 0);
//     }

// }



