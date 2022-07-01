// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./shared/libraries/SafeMath.sol";
import "./shared/interfaces/IERC20.sol";
import "./shared/interfaces/IMVD.sol";

import "./shared/types/MetaVaultAC.sol";

contract Redeem is MetaVaultAC {
    using SafeMath for uint256;

    address public principle; // Principle token
    address public mvd; // Staking token

    //address public MVD;
    //address public DAI;

    uint256 public RFV; // 272

    uint256 public mvdBurned;
    uint256 public dueDate = 1719724769; // Sun Jun 30 2024 05:19:29 GMT+0000

    constructor(
        address _mvd,
        address _principle,
        uint256 _RFV,
        address _authority
    ) MetaVaultAC(IMetaVaultAuthority(_authority)) {
        mvd = _mvd;
        principle = _principle;
        RFV = _RFV;
    }

    // _RFV must be given with 2 decimals -> $2.72 = 272
    function setRfv(uint256 _RFV) external onlyGovernor {
        RFV = _RFV;
    }

    function setTokens(address _mvd, address _principle) external onlyGovernor {
        mvd = _mvd;
        principle = _principle;
    }

    function setDueDate(uint256 _dueDate) external onlyGovernor {
        dueDate = _dueDate;
    }

    function transfer(
        address _to,
        uint256 _amount,
        address _token
    ) external onlyGovernor {
        require(_amount <= IERC20(_token).balanceOf(address(this)), "Not enough balance");

        IERC20(_token).transfer(_to, _amount);
    }

    // Amount must be given in MVD, which has 9 decimals
    function swap(uint256 _amount) external {
        require(block.timestamp <= dueDate, "Swap disabled.");

        require(_amount <= IERC20(mvd).balanceOf(msg.sender), "You need more MVD");
        require(_amount > 0, "amount is 0");

        require(IERC20(mvd).allowance(msg.sender, address(this)) >= _amount, "You need to approve this contract to spend your MVD");

        uint256 _value = _amount.mul(RFV).mul(10000000);

        require(_value <= IERC20(principle).balanceOf(address(this)), "Please wait or contact Metavault team");

        IMVD(mvd).burnFrom(msg.sender, _amount);

        mvdBurned = mvdBurned.add(_amount);

        IERC20(principle).transfer(msg.sender, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IERC20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IMVD is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../interfaces/IMetaVaultAuthority.sol";

abstract contract MetaVaultAC {
    IMetaVaultAuthority public authority;

    event AuthorityUpdated(IMetaVaultAuthority indexed authority);

    constructor(IMetaVaultAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), "MetavaultAC: caller is not the Governer");
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), "MetavaultAC: caller is not the Policy");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), "MetavaultAC: caller is not the Vault");
        _;
    }

    function setAuthority(IMetaVaultAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMetaVaultAuthority {
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}