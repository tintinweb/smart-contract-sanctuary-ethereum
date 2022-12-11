/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMarket {
    function recall(uint amount) external;
    function totalDebt() external view returns (uint);
    function borrowPaused() external view returns (bool);
}

interface IDola {
    function mint(address to, uint amount) external;
    function burn(uint amount) external;
    function balanceOf(address user) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
}

interface IDBR {
    function markets(address) external view returns (bool);
}

/**
@title The Market Fed
@notice Feds are a class of contracts in the Inverse Finance ecosystem responsible for minting and burning DOLA.
 This specific Fed can expand DOLA supply into markets and contract DOLA supply from markets.
*/
contract Fed {

    IDBR public immutable dbr;
    IDola public immutable dola;
    address public gov;
    address public chair;
    uint public supplyCeiling;
    uint public globalSupply;
    mapping (IMarket => uint) public supplies;
    mapping (IMarket => uint) public ceilings;

    constructor (IDBR _dbr, IDola _dola, address _gov, address _chair, uint _supplyCeiling) {
        dbr = _dbr;
        dola = _dola;
        gov = _gov;
        chair = _chair;
        supplyCeiling = _supplyCeiling;
    }

    /**
    @notice Change the governance of the Fed contact. Only callable by governance.
    @param _gov The address of the new governance contract
    */
    function changeGov(address _gov) public {
        require(msg.sender == gov, "ONLY GOV");
        gov = _gov;
    }

    /**
    @notice Set the supply ceiling of the Fed. Only callable by governance.
    @param _supplyCeiling Amount to set the supply ceiling to
    */
    function changeSupplyCeiling(uint _supplyCeiling) public {
        require(msg.sender == gov, "ONLY GOV");
        supplyCeiling = _supplyCeiling;
    }

    /**
    @notice Set a market's isolated ceiling of the Fed. Only callable by governance.
    @param _market Market to set the ceiling for
    @param _ceiling Amount to set the ceiling to
    */
    function changeMarketCeiling(IMarket _market, uint _ceiling) public {
        require(msg.sender == gov, "ONLY GOV");
        ceilings[_market] = _ceiling;
    }

    /**
    @notice Set the chair of the fed. Only callable by governance.
    @param _chair Address of the new chair.
    */
    function changeChair(address _chair) public {
        require(msg.sender == gov, "ONLY GOV");
        chair = _chair;
    }

    /**
    @notice Set the address of the chair to the 0 address. Only callable by the chair.
    @dev Useful for immediately removing chair powers in case of a wallet compromise.
    */
    function resign() public {
        require(msg.sender == chair, "ONLY CHAIR");
        chair = address(0);
    }

    /**
    @notice Expand the amount of DOLA by depositing the amount into a specific market.
    @dev While not immediately dangerous to the DOLA peg, make sure the market can absorb the new potential supply. Market must have a positive ceiling before expansion.
    @param market The market to add additional DOLA supply to.
    @param amount The amount of DOLA to mint and supply to the market.
    */
    function expansion(IMarket market, uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        require(dbr.markets(address(market)), "UNSUPPORTED MARKET");
        require(market.borrowPaused() != true, "CANNOT EXPAND PAUSED MARKETS");
        dola.mint(address(market), amount);
        supplies[market] += amount;
        globalSupply += amount;
        require(globalSupply <= supplyCeiling);
        require(supplies[market] <= ceilings[market]);
        emit Expansion(market, amount);
    }

    /**
    @notice Contract the amount of DOLA by withdrawing some amount of DOLA from a market, before burning it.
    @dev Markets can have more DOLA in them than they've been supplied, due to force replenishes. This call will revert if trying to contract more than have been supplied.
    @param market The market to withdraw DOLA from
    @param amount The amount of DOLA to withdraw and burn.
    */
    function contraction(IMarket market, uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        require(dbr.markets(address(market)), "UNSUPPORTED MARKET");
        uint supply = supplies[market];
        require(amount <= supply, "AMOUNT TOO BIG"); // can't burn profits
        market.recall(amount);
        dola.burn(amount);
        supplies[market] -= amount;
        globalSupply -= amount;
        emit Contraction(market, amount);
    }

    /**
    @notice Gets the profit of a market.
    @param market The market to withdraw profit from.
    @return A uint representing the profit of the market.
    */
    function getProfit(IMarket market) public view returns (uint) {
        uint marketValue = dola.balanceOf(address(market)) + market.totalDebt();
        uint supply = supplies[market];
        if(supply >= marketValue) return 0;
        return marketValue - supply;
    }

    /**
    @notice Takes profit from a market
    @param market The market to take profit from.
    */
    function takeProfit(IMarket market) public {
        uint profit = getProfit(market);
        if(profit > 0) {
            market.recall(profit);
            dola.transfer(gov, profit);
        }
    }


    event Expansion(IMarket indexed market, uint amount);
    event Contraction(IMarket indexed market, uint amount);

}