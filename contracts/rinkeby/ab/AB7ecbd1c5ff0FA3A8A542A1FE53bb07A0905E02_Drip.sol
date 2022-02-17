// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../types/Ownable.sol";

contract Drip is Ownable {
    using SafeMath for uint256;

    mapping(address => bool) public dripped;

    IERC20 public PUNK;
    IERC20 public PUNKWEETH;
    IERC20 public AFLOOR;
    IERC20 public WEETH;

    constructor(address _punk, address _punkWeeth, address _aFloor, address _weeth) {
      require(_punk != address(0), "Punk address not provided");
      require(_punkWeeth != address(0), "PunkWeeth address not provided");
      require(_aFloor != address(0), "aFloor address not provided");
      require(_weeth != address(0), "Weeth address not provided");

      PUNK = IERC20(_punk);
      PUNKWEETH = IERC20(_punkWeeth);
      AFLOOR = IERC20(_aFloor);
      WEETH = IERC20(_weeth);
    }

    function drip() public {
        require(!dripped[msg.sender], "Already dripped");
        dripped[msg.sender] = true;
        PUNK.transfer(msg.sender, 500_000_000_000_000_000); // 0.5 PUNK
        PUNKWEETH.transfer(msg.sender, 8_000_000_000_000_000_000); // 8 PUNKWEETH SLP
        AFLOOR.transfer(msg.sender, 1000_000_000_000); // 1000 AFLOOR
        WEETH.transfer(msg.sender, 10_000_000_000_000_000_000); // 10 WEETH
    }

    function fill() public {
        PUNK.transferFrom(msg.sender, address(this), 50000_000_000_000_000_000); // 50 PUNK
        PUNKWEETH.transferFrom(msg.sender, address(this), 800_000_000_000_000_000_000); // 80 PUNKWEETH SLP
        AFLOOR.transferFrom(msg.sender, address(this), 100000_000_000_000); // 100000 AFLOOR
        WEETH.transferFrom(msg.sender, address(this), 1000_000_000_000_000_000_000); // 1000 WEETH
    }

    function withdraw() external onlyOwner() {
        PUNK.transfer(owner(), PUNK.balanceOf(address(this))); // 0.5 PUNK
        PUNKWEETH.transfer(owner(), PUNKWEETH.balanceOf(address(this))); // 8 PUNKWEETH SLP
        AFLOOR.transfer(owner(), AFLOOR.balanceOf(address(this))); // 1000 AFLOOR
        WEETH.transfer(owner(), WEETH.balanceOf(address(this))); // 10 WEETH
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
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
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
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

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPulled( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}