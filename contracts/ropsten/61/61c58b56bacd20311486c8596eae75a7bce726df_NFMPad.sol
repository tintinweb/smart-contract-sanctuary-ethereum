/**
 *Submitted for verification at Etherscan.io on 2022-06-22
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
    function _checkWLSC(address, address) external pure returns (bool);

    function _getNFM() external pure returns (address);

    function _getMinting() external pure returns (address);

    function _getUV2Pool() external pure returns (address);

    function _getNFMStakingTreasuryERC20() external pure returns (address);

    function _getDaoReserveERC20() external pure returns (address);

    function _getTreasury() external pure returns (address);

    function _getDistribute() external pure returns (address);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMMINTING
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmMinting {
    function _updateBNFTAmount() external returns (bool);

    function calculateParts(uint256 amount)
        external
        pure
        returns (
            uint256 UVamount,
            uint256 StakeAmount,
            uint256 GovAmount,
            uint256 DevsAmount,
            uint256 TreasuryAmount
        );

    function _minting(address sender) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMPad.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract regulates the pump and dump safety
/// @dev As soon as a new address receives NFM, this is automatically included and monitored by this protocol.
///           ***All internal smart contracts belonging to the controller are excluded from the PAD check.***
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMPad {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    INfmController public _Controller;
    address private _SController;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    PAD FEES AND LIMITS
    PAD1 NORMAL DAILY LIMIT = 1,000,000 NFM
    PAD2 MAX LIMIT AFTER WHITELISTING = 1,500,000 NFM
    PADFEE FOR BEEING WHITELISTED = 10,000 NFM
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 private PAD1 = 1000000 * 10**18;
    uint256 private PAD2 = 1500000 * 10**18;
    uint256 private PADFEE = 10000 * 10**18;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    PadWL (Investor address, Timestamp, paid Fee)
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event PadWL(address indexed Sender, uint256 indexed Time, uint256 WLfee);
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    _PADprotection (NFM Owner address, sended amount NFM);
    _PADtimePointer (NFM Owner address, timeinterval of 24 Hours);
    _PADWhiteisting (NFM Owner address, boolean integer "indicating 1 if true 0 if false" for whitelisting activation);
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) public _PADprotection;
    mapping(address => uint256) public _PADtimePointer;
    mapping(address => uint256) public _PADWhitelisting;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    onlyOwner       => Only Controller listed Contracts and Owner can interact with this contract.
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }

    constructor(address Controller) {
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_PADCHECK(sender, amount) returns (bool);
    This function is called before each transfer. The timestamp, daily limit and whitelisting are checked.
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _PADCHECK(address from, uint256 amount) public onlyOwner returns (bool) {
        if (_PADtimePointer[from] > 0) {
            //inisialised
            if (_PADtimePointer[from] > block.timestamp) {
                //in time
                //IS LISTED
                if (_PADWhitelisting[from] > 0) {
                    if ((amount + _PADprotection[from]) <= PAD2) {
                        _PADprotection[from] += amount;
                        return true;
                    } else {
                        return false;
                    }
                    //IS NOT LISTED
                } else {
                    if ((amount + _PADprotection[from]) <= PAD1) {
                        _PADprotection[from] += amount;
                        return true;
                    } else {
                        return false;
                    }
                }
                //IS OUT OF TIME
            } else {
                //not in time new Start
                _PADtimePointer[from] = block.timestamp + (3600 * 24);
                _PADWhitelisting[from] = 0;
                _PADprotection[from] = 0;
                if (amount <= PAD1) {
                    _PADprotection[from] += amount;
                    return true;
                } else {
                    return false;
                }
            }
            //FIRST TRANSFER FROM THIS ACCOUNT
            //PAD NEEDS TO BE INICIALISED
        } else {
            _PADtimePointer[from] = block.timestamp + (3600 * 24);
            _PADprotection[from] = 0;
            if (_PADWhitelisting[from] > 0) {
                if (amount <= PAD2) {
                    _PADprotection[from] += amount;
                    return true;
                } else {
                    return false;
                }
            } else {
                _PADWhitelisting[from] = 0;
                if (amount <= PAD1) {
                    _PADprotection[from] += amount;
                    return true;
                } else {
                    return false;
                }
            }
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @balancePAD(address account) returns (uint256);
    This function returns the daily remaining PAD limit
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function balancePAD(address account) public view returns (uint256) {
        if (_PADtimePointer[account] > block.timestamp) {
            if (_PADWhitelisting[account] < 1) {
                return SafeMath.sub(PAD1, _PADprotection[account]);
            } else {
                return SafeMath.sub(PAD2, _PADprotection[account]);
            }
        } else {
            return PAD1;
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_padWL() returns (bool);
    This function performs the whitelisting. For this function to work, the investor must have approved 10,000 NFM to the contract.
    The fees are distributed in equal proportions as in the minting Contract.
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _padWL() public virtual returns (bool) {
        //Client must have approved allowance to PDA contract first
        if (_PADtimePointer[msg.sender] > 0) {} else {
            _PADtimePointer[msg.sender] = block.timestamp + (3600 * 24);
            _PADprotection[msg.sender] = 0;
            _PADWhitelisting[msg.sender] = 0;
        }
        require(
            _PADWhitelisting[msg.sender] == 0 ||
                (_PADWhitelisting[msg.sender] == 1 &&
                    _PADtimePointer[msg.sender] < block.timestamp),
            "_T"
        );
        require(msg.sender != address(0), "0A");
        require(
            IERC20(address(_Controller._getNFM())).allowance(
                msg.sender,
                address(this)
            ) >= PADFEE,
            "<B"
        );
        INfmMinting CalcFee = INfmMinting(_Controller._getMinting());
        (
            uint256 UVamount,
            uint256 StakeAmount,
            uint256 GovAmount,
            uint256 DevsAmount,
            uint256 TreasuryAmount
        ) = CalcFee.calculateParts(PADFEE);
        require(
            IERC20(address(_Controller._getNFM())).transferFrom(
                msg.sender,
                _Controller._getUV2Pool(),
                UVamount
            ) == true,
            "<B"
        );
        require(
            IERC20(address(_Controller._getNFM())).transferFrom(
                msg.sender,
                _Controller._getNFMStakingTreasuryERC20(),
                StakeAmount
            ) == true,
            "<B"
        );
        require(
            IERC20(address(_Controller._getNFM())).transferFrom(
                msg.sender,
                _Controller._getDaoReserveERC20(),
                GovAmount
            ) == true,
            "<B"
        );
        require(
            IERC20(address(_Controller._getNFM())).transferFrom(
                msg.sender,
                _Controller._getDistribute(),
                DevsAmount
            ) == true,
            "<B"
        );
        require(
            IERC20(address(_Controller._getNFM())).transferFrom(
                msg.sender,
                _Controller._getTreasury(),
                TreasuryAmount
            ) == true,
            "<B"
        );
        _PADWhitelisting[msg.sender] = 1;
        emit PadWL(msg.sender, block.timestamp, PADFEE);
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getPadPointer(address account) returns (uint256);
    This function returns the time interval
    This interval is renewed as soon as 24 hours have elapsed for another 24 hours. The pad limit is also reset to 0. See Function @_PADCHECK
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getPadPointer(address account) public view returns (uint256) {
        return _PADtimePointer[account];
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getPadWLState(address account) returns (bool);
    This function returns a boolean value whether the WL is enabled or not.
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getPadWLState(address account) public view returns (bool) {
        if (_PADWhitelisting[account] == 0) {
            return false;
        } else {
            return true;
        }
    }
}