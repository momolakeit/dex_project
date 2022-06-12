pragma solidity ^0.8.0;

import "./token.sol";
import "./momoSwapToken.sol";
import "./librarys/Math.sol";
contract DEX is MomoSwapToken {
   Token token;
   uint256 numberOfDeposits;
   uint256 fee = 3;
   uint256 reserveMatic;
   uint256 reserveToken;
   struct Deposit{
      uint256 depositId;
      uint256 depositAmount;
      uint256 timeOfDeposit;
   }
   mapping(address => Deposit) userDeposit;
   //gives out the number of deposit made by a certain blocktime0
   mapping(uint256 => uint256) numberOfDepositsByTime;
   address public tokenAddress;
   constructor(address _token,string memory _tokenName, string memory _symbol) MomoSwapToken(string(abi.encodePacked(_tokenName, "/matic")),_symbol) payable{
      require(msg.value > 0 , "You have to at least deposit something to start a DEX");
      tokenAddress = _token;
      token = Token(address(tokenAddress));
   }
   function buy() payable public {
      uint256 amountTobuy = msg.value;
     
      uint256 dexBalance = token.balanceOf(address(this));
     
      require(amountTobuy > 0, "You need to send some Ether");
      require(amountTobuy <= dexBalance*10**token.decimals(), "Not enough tokens in the reserve");
      amountTobuy -= (amountTobuy/10**2)*fee ;
      
      token.transfer(msg.sender, amountTobuy);
   }

   function sell(uint256 amount) public {
      require(amount > 0, "You need to sell at least some tokens");
     
      amount -= (amount/10**2)*fee ;
     
      uint256 approvedAmt = token.allowance(msg.sender, address(this));
      require(approvedAmt >= amount, "Check the token allowance");
     
      token.transferFrom(msg.sender, payable(address(this)), amount);
      payable(msg.sender).transfer(amount);
   }
   
   function deposit(uint256 amount) payable public {
      require(amount > 0, "You have to at least deposit something");
      require(msg.value > 0 , "You have to at least deposit something");
      
      mintLpToken(msg.sender,msg.value,amount);

      token.transferFrom(msg.sender,payable(address(this)),amount);
   }

   function remove() public {
      uint addressLpTokenBalance = balances[msg.sender]; 
   
      uint maticAmount = address(this).balance*addressLpTokenBalance/totalSupply_;
      uint tokenAmount = token.balanceOf(address(this))*addressLpTokenBalance/totalSupply_;
   
      burn(msg.sender);
   
      payable(msg.sender).transfer(maticAmount);
      token.transfer(msg.sender,tokenAmount);
   }

   function mintLpToken(address to,uint256 maticAmount,uint256 tokenAmount) private{
      uint256 liquidity;
    
      if(totalSupply_ == 0){
         liquidity =  Math.sqrt(tokenAmount * maticAmount);
      }else{
         liquidity = (tokenAmount*token.balanceOf(address(this)))/totalSupply_;//how much lp token the user should get, only need to get ration of one token since token deposited should be proportional
      }
      mint(to,liquidity);
   }
}