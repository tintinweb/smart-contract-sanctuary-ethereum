/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

/*

LIBRARY

 */
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

/*

INTERFACES

 */
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

/*

CONTRACT

 */
contract NFMPad {
    using SafeMath for uint256;
    address private _Owner;
    INfmController public _Controller;
    address private _SController;
    uint256 private PAD1 = 1000000 * 10**18;
    uint256 private PAD2 = 1500000 * 10**18;
    uint256 private PADFEE = 10000 * 10**18;
    event PadWL(address indexed Sender, uint256 indexed Time, uint256 WLfee);
    mapping(address => uint256) public _PADprotection;
    mapping(address => uint256) public _PADtimePointer;
    mapping(address => uint256) public _PADWhitelisting;

    constructor(address Controller) {
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
    }

    /*
    PRECHECK PAD SECURITY ON EVERY TRANSFER ON NOT EXCLUDED
     */
    function _PADCHECK(address from, uint256 amount) public returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        if (_PADtimePointer[from] > 0) {
            //inisialised
            if (_PADtimePointer[from] > block.timestamp) {
                //in time
                //IS LISTED
                if (_PADWhitelisting[from] > 0) {
                    require(amount + _PADprotection[from] <= PAD2, "PAD");
                        _PADprotection[from] += amount;
                        return true;
                    
                    //IS NOT LISTED
                } else {
                    require(amount + _PADprotection[from] <= PAD1, "PAD");
                        _PADprotection[from] += amount;
                        return true;
                    
                }
                //IS OUT OF TIME
            } else {
                //not in time new Start
                _PADtimePointer[from] = block.timestamp + (3600 * 24);
                _PADWhitelisting[from] = 0;
                _PADprotection[from] = 0;
                require(amount <= PAD1, "PAD");
                    _PADprotection[from] += amount;
                    return true;
            }
            //FIRST TRANSFER FROM THIS ACCOUNT
            //PAD NEEDS TO BE INICIALISED
        } else {
            _PADtimePointer[from] = block.timestamp + (3600 * 24);
            _PADprotection[from] = 0;
            if (_PADWhitelisting[from] > 0) {
                require(amount <= PAD2, "PAD");
                    _PADprotection[from] += amount;
                    return true;
            } else {
                _PADWhitelisting[from] = 0;
                require(amount <= PAD1, "PAD");
                    _PADprotection[from] += amount;
                    return true;                
            }
        }
    }

    /*
    SHOW REMAINING BALANCES ON PAD
     */
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

    /*

    WILL BE CALLED FROM CLIENT DIRECTLY

    */
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

    function _getPadPointer(address account) public view returns (uint256) {
        return _PADtimePointer[account];
    }

    function _getPadWLState(address account) public view returns (bool) {
        if (_PADWhitelisting[account] == 0) {
            return false;
        } else {
            return true;
        }
    }
}