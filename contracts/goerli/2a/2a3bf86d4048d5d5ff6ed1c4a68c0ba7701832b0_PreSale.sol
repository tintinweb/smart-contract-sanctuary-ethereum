/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBEP20 {

        function balanceOf(address account) external view returns (uint256);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns(uint256);
    }
    

contract PreSale{
    
    // IBEP20 genToken;
    IBEP20 busdToken;

    struct tokenBuyer{

        address userAddress;
        uint256 userTokens;
    }

    bool public preSaleState;
    uint256 public totalBuyers;
    uint256 public preSalePrice;
    uint256 public totalSoldTokens;
    uint256 public preSaleCap = 100000 * 1e18;
    
    address public owner;
    address busdWalletAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address genTokenWalletAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    mapping(uint256 => tokenBuyer) public tokenBuyerInfo; 

    event preSellInfo(address buyer, uint256 getPrice, uint256 soldTokens);

    
    constructor(/*address _genToken,*/ address _busdToken) {
        
        owner = msg.sender;
        preSalePrice = 10;              // Price in USD (10 usd aginst one Gen)
        // genToken = IBEP20(_genToken);
        busdToken = IBEP20(_busdToken);
    }

    
    // need amount in Wei
    
    function sellInPreSale(uint256 _amount)  external PresaleState {

        require(totalSoldTokens <= preSaleCap, "All genToken are Sold.");
                
        uint256 totalPrice = _amount * preSalePrice;

        // console.log("total _amount : ", _amount );
        // console.log("total proice : ", totalPrice );
        // console.log("usdToken.balanceOf(msg.sender) : ", busdToken.balanceOf(msg.sender) );
        // console.log("genToken.balanceOf(genTokenWalletAddress) : ", genToken.balanceOf(genTokenWalletAddress));


        require(busdToken.balanceOf(msg.sender) >=  totalPrice, "You donot have sufficienyt amount of usd token to buy Gen.");
        // require(genToken.balanceOf(genTokenWalletAddress) >= _amount, "Owner didnt have sufficient amount of gen Token to Sell right Now, Please try later!.");
        

        busdToken.transferFrom(msg.sender, busdWalletAddress, totalPrice);
        // genToken.transferFrom(genTokenWalletAddress, msg.sender, _amount);

        tokenBuyerInfo[totalBuyers].userAddress = msg.sender;
        tokenBuyerInfo[totalBuyers].userTokens = _amount;

        totalBuyers++;
        totalSoldTokens += _amount;

        emit preSellInfo (msg.sender, totalPrice, _amount);
    }

    function removeUsers() external onlyOwner {
        totalBuyers = 0;
    }


    function getAllBuyersInfo()public view returns (tokenBuyer[] memory ){

        tokenBuyer[] memory buyerTokenInfo = new tokenBuyer[](totalBuyers);
        
        for (uint i = 0; i < totalBuyers; i++) {

            tokenBuyer memory _tokenBuyer = tokenBuyerInfo[i];
            buyerTokenInfo[i] = _tokenBuyer;
        }

        return buyerTokenInfo;
    }

    
    function usdUserUsdtBalance() public view returns(uint256 balance){
           balance = busdToken.balanceOf(msg.sender);
    } 

    function setPreSalePrice(uint256 _newPrice) external onlyOwner {
        preSalePrice = _newPrice;
    }

    function setPreSaleState(uint256 _state) external onlyOwner {

        require(_state == 0 || _state == 1, "state vale eithr 1 or 0 only.");
        
        if (_state == 0){

            preSaleState = false;
        }
        else{

            preSaleState = true;
        }
    }

    modifier PresaleState () {
        require(preSaleState, "PreSale is not startrd Yet");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}