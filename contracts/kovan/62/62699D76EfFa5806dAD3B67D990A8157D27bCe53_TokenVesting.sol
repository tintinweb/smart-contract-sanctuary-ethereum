pragma solidity ^0.4.11;

import './ERC20Basic.sol';
import './SafeERC20.sol';
import './Ownable.sol';
import './Math.sol';
import './SafeMath.sol';

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */

library Library {
  struct TokenVestingData {
      address beneficiary;
      uint256 cliff;
      uint256 start;
      uint256 duration;
      bool revocable;
      bool exist;
      mapping (address => uint256) released;
      mapping (address => bool) revoked;
   }
}

contract TokenVesting is Ownable {
  using Library for Library.TokenVestingData;
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */

  mapping(uint256 => Library.TokenVestingData) tokens;
  uint256 count;

  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);
    uint256 cliff = _start.add(_cliff);
    tokens[count] = Library.TokenVestingData(_beneficiary, cliff, _start, _duration, _revocable, true);
    count++;
  }

  function addMoney() public payable {

  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token, uint256 id) public {
    require(tokens[id].exist == true, "The supplied Id does not exist");

    uint256 unreleased = releasableAmount(token, id);

    require(unreleased > 0);

    tokens[id].released[token] = tokens[id].released[token].add(unreleased);

    token.safeTransfer(tokens[id].beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token, uint256 id) public onlyOwner {
    require(tokens[id].exist == true, "The supplied Id does not exist");
    require(tokens[id].revocable);
    require(!tokens[id].revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token, id);
    uint256 refund = balance.sub(unreleased);

    tokens[id].revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token, uint256 id) public constant returns (uint256) {
    require(tokens[id].exist == true, "The supplied Id does not exist");
    return vestedAmount(token, id).sub(tokens[id].released[token]);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token, uint256 id) public constant returns (uint256) {
    require(tokens[id].exist == true, "The supplied Id does not exist");
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(tokens[id].released[token]);

    if (now < tokens[id].cliff) {
      return 0;
    } else if (now >= tokens[id].start.add(tokens[id].duration) || tokens[id].revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(tokens[id].start)).div(tokens[id].duration);
    }
  }
}