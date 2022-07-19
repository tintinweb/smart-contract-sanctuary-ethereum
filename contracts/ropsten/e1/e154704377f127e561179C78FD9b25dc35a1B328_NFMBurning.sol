/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// LIBRARIES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// SAFEMATH its a Openzeppelin Lib. Check out for more info @ https://docs.openzeppelin.com/contracts/2.x/api/math
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getNFM() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMBurning.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract regulates the burning of the NFM token and initializes itself after 4 years of logic launch
/// @dev As soon as the timestamp for Burning Start has passed, the Burning initializes. A mechanism in the transfer
///           protocol of the NFM token then automatically charges a burning fee of 4%. This amount is then automatically
///           deducted from the amount sent.
///           This burning process is structured as follows:
///             - 2% burning fee
///             - 2% community fee
///
///             As soon as the total supply of the NFM has reached 1,000,000,000 then the 2% burning fee will be converted
///             into a community fee. From then on, there will be a lifelong 4% community fee on every Transaction.
///                     ***The fee is only charged if the transaction exceeds a minimum amount of 2 NFM.***
///             ***All internal smart contracts belonging to the controller are excluded from the Burning Events.***
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMBurning {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    INfmController private _Controller;
    address private _Owner;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    FinalTotalSupply    => 1,000,000,000 NFM
    Once this amount has been reached, the burning will stop and the 2% will be an additional community fee. In addition, 
    the BuyBack Program begins when the burning ends
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 private FinalTotalSupply = 1000000000 * 10**18;

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @checkburn(uint256 amount) returns (bool, bool, uint256, uint256);
    This function checks the burning if the final amount of 1 billion has not yet been reached and returns the following parameters to the calling
    contract:
        - Status whether burning is necessary (true if yes and false if not)
        - Type of fee (true Burning if burning fee and false if only community fee)
        - Burning Fee amount on the transaction
        - Community Fee amount on the transaction               
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function checkburn(uint256 amount)
        public
        view
        returns (
            bool state,
            bool typ,
            uint256 bfee,
            uint256 stakefee
        )
    {
        //RESTING FEES IF BURNING STARTED
        uint256 burnfee = 0;
        if (amount > 2 * 10**18) {
            burnfee = _calcFee(amount);
            uint256 lasting = IERC20(address(_Controller._getNFM()))
                .totalSupply() - burnfee;
            if (lasting >= 1000000000 * 10**18) {
                return (true, true, burnfee, burnfee);
            } else {
                return (true, false, 0, burnfee);
            }
        } else {
            return (false, false, 0, 0);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_calcFee(uint256 amount) returns (uint256);
    This function calculates the 2% fee on the transaction
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _calcFee(uint256 amount) public pure returns (uint256) {
        uint256 burnPercent = SafeMath.div(SafeMath.mul(amount, 2), 100);
        return burnPercent;
    }
}