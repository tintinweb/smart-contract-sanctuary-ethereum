/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
// https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

// This is a proof of concept for a stablecoin creator that supports any ERC20 token.

contract Stability {

    mapping(uint => ERC20) MarketToken;
    mapping(uint => OracleViewer) MarketOracle;
    mapping(uint => STBtoken) Stablecoin;
    mapping(uint => uint) public MarketUSDCdebt;
    mapping(uint => uint) public MarketDAIdebt;
    mapping(uint => mapping(address => uint)) UserBalance;
    mapping(uint => mapping(address => uint)) Debt;
    mapping(uint => uint) CurrentPrice;
    uint Nonce;
    
    ERC20 USDC = ERC20(address(0));
    ERC20 DAI = ERC20(address(0));

    function CreateStablecoin(ERC20 Token, OracleViewer OracleAddress, STBtoken BlankTemplate) public {

        MarketToken[Nonce] = Token;
        MarketOracle[Nonce] = OracleAddress;

        // Makes the name of the token ____ USD, like if you make a stablecoin using SHIB, this would make the name SHIB USD.
        // Also checks if the contract you entered is actually an ERC20
        BlankTemplate.initalize(append(Token.name(), " USD"), append(Token.symbol(), " USD"));

        Stablecoin[Nonce] = BlankTemplate;

        Nonce += 1;
    }

    function mintFromUSDC(uint MarketID, uint amount) public {

        USDC.transferFrom(msg.sender, address(this), amount);

        MarketUSDCdebt[MarketID] += amount;
        mint(MarketID, msg.sender, amount*(10**12));
    }

    function mintFromDAI(uint MarketID, uint amount) public {

        DAI.transferFrom(msg.sender, address(this), amount);

        MarketDAIdebt[MarketID] += amount;
        mint(MarketID, msg.sender, amount);
    }

    function redeemForToken(uint MarketID, uint repayAmount, uint redeemAmount) public {

        burn(MarketID, msg.sender, repayAmount);
        Debt[MarketID][msg.sender] -= repayAmount;

        uint aval = MarketOracle[MarketID].getPrice()*(UserBalance[MarketID][msg.sender]/10**8)-Debt[MarketID][msg.sender];

        aval = 40*(aval/100); // inverse of 60 out of 100 is 40 

        require(aval > redeemAmount, "Your debt is too high to make this withdraw.");

        MarketToken[MarketID].transfer(address(this), redeemAmount);
    }

    function redeemForUSDC(uint MarketID, uint amount) public {

        burn(MarketID, msg.sender, amount);

        USDC.transfer(msg.sender, amount/(10**12));
    }

    function redeemForDAI(uint MarketID, uint amount) public {

        burn(MarketID, msg.sender, amount);

        DAI.transfer(msg.sender, amount);
    }

    function mintFromToken(uint MarketID, uint amount, uint mintAmount) public {

        MarketToken[MarketID].transferFrom(msg.sender, address(this), amount); 
        UserBalance[MarketID][msg.sender] += amount; 

        uint aval = MarketOracle[MarketID].getPrice()*(UserBalance[MarketID][msg.sender]/10**8)-Debt[MarketID][msg.sender];

        aval = 60*(aval/100); // For the purpose of testing, all tokens have a 60% LTV.

        Debt[MarketID][msg.sender] += mintAmount;

        require(aval > mintAmount, "You don't have enough collateral to mint this many tokens");

        mint(MarketID, msg.sender, mintAmount);
    }

    function liquidate(uint MarketID, address Victim) public {

        require(Health(MarketID, Victim) < 10**18, "This address isn't vulnerable to be liquidated");

        Stablecoin[MarketID].transferFrom(msg.sender, address(this), Debt[MarketID][Victim]);

        Debt[MarketID][Victim] = 0;

        MarketToken[MarketID].transfer(msg.sender, UserBalance[MarketID][Victim]);

    }

    function mint(uint MarketID, address Who, uint amount) internal {

        Stablecoin[MarketID].mint(amount, Who);
    }

    function burn(uint MarketID, address Who, uint amount) internal {

        Stablecoin[MarketID].burn(amount, Who);
    }

    function UpdateAllOracles() public {

        uint MarketID;

        while(MarketToken[MarketID] != ERC20(address(0))){

            UpdateOracle(MarketID);
            MarketID += 1;
        }
    }

    function UpdateOracle(uint MarketID) public {

        CurrentPrice[MarketID] = MarketOracle[MarketID].getPrice();
    }

    function Health(uint MarketID, address Who) public view returns (uint){

        uint aval = CurrentPrice[MarketID]*(UserBalance[MarketID][Who]/10**8);

        return (Debt[MarketID][Who]*(10**18))/(60*(aval/100));
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b));
    }

}

interface STBtoken{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
    function name() external view returns(string memory);
    function initalize(string memory, string memory) external;
    function mint(uint, address) external;
    function burn(uint, address) external;
    function forceTransfer(address, address, uint) external;
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
}

interface OracleViewer{

    // Chainlink Dev Docs https://docs.chain.link/docs/
    function getPrice() external view returns (uint);
}