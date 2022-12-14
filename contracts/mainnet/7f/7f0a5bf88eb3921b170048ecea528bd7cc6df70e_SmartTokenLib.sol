/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

pragma solidity ^0.4.24;

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.4.24;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

pragma solidity ^0.4.24;



/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

pragma solidity ^0.4.24;

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <[email protected]π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoTokens.sol

pragma solidity ^0.4.24;

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <[email protected]π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param _from address The address that is transferring the tokens
  * @param _value uint256 the amount of the specified token
  * @param _data Bytes The data passed from the caller.
  */
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoContracts.sol

pragma solidity ^0.4.24;

/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <[email protected]π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param _contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

// File: openzeppelin-solidity/contracts/ownership/NoOwner.sol

pragma solidity ^0.4.24;



/**
 * @title Base contract for contracts that should not own things.
 * @author Remco Bloemen <[email protected]π.com>
 * @dev Solves a class of errors where a contract accidentally becomes owner of Ether, Tokens or
 * Owned contracts. See respective base contracts for details.
 */
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

// File: contracts/TokenStorageLib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;

/** @title TokenStorageLib
 * @dev Implementation of an[external storage for tokens.
 */
library TokenStorageLib {

    using SafeMath for uint;

    struct TokenStorage {
        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
        uint totalSupply;
    }

    /**
     * @dev Increases balance of an address.
     * @param self Token storage to operate on.
     * @param to Address to increase.
     * @param amount Number of units to add.
     */
    function addBalance(TokenStorage storage self, address to, uint amount)
        external
    {
        self.totalSupply = self.totalSupply.add(amount);
        self.balances[to] = self.balances[to].add(amount);
    }

    /**
     * @dev Decreases balance of an address.
     * @param self Token storage to operate on.
     * @param from Address to decrease.
     * @param amount Number of units to subtract.
     */
    function subBalance(TokenStorage storage self, address from, uint amount)
        external
    {
        self.totalSupply = self.totalSupply.sub(amount);
        self.balances[from] = self.balances[from].sub(amount);
    }

    /**
     * @dev Sets the allowance for a spender.
     * @param self Token storage to operate on.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @param amount Qunatity of allowance.
     */
    function setAllowed(TokenStorage storage self, address owner, address spender, uint amount)
        external
    {
        self.allowed[owner][spender] = amount;
    }

    /**
     * @dev Returns the supply of tokens.
     * @param self Token storage to operate on.
     * @return Total supply.
     */
    function getSupply(TokenStorage storage self)
        external
        view
        returns (uint)
    {
        return self.totalSupply;
    }

    /**
     * @dev Returns the balance of an address.
     * @param self Token storage to operate on.
     * @param who Address to lookup.
     * @return Number of units.
     */
    function getBalance(TokenStorage storage self, address who)
        external
        view
        returns (uint)
    {
        return self.balances[who];
    }

    /**
     * @dev Returns the allowance for a spender.
     * @param self Token storage to operate on.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @return Number of units.
     */
    function getAllowed(TokenStorage storage self, address owner, address spender)
        external
        view
        returns (uint)
    {
        return self.allowed[owner][spender];
    }

}

// File: contracts/TokenStorage.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;




/**
 * @title TokenStorage
 * @dev External storage for tokens.
 * The storage is implemented in a separate contract to maintain state
 * between token upgrades.
 */
contract TokenStorage is Claimable, CanReclaimToken, NoOwner {

    using TokenStorageLib for TokenStorageLib.TokenStorage;

    TokenStorageLib.TokenStorage internal tokenStorage;

    /**
     * @dev Increases balance of an address.
     * @param to Address to increase.
     * @param amount Number of units to add.
     */
    function addBalance(address to, uint amount) external onlyOwner {
        tokenStorage.addBalance(to, amount);
    }

    /**
     * @dev Decreases balance of an address.
     * @param from Address to decrease.
     * @param amount Number of units to subtract.
     */
    function subBalance(address from, uint amount) external onlyOwner {
        tokenStorage.subBalance(from, amount);
    }

    /**
     * @dev Sets the allowance for a spender.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @param amount Qunatity of allowance.
     */
    function setAllowed(address owner, address spender, uint amount) external onlyOwner {
        tokenStorage.setAllowed(owner, spender, amount);
    }

    /**
     * @dev Returns the supply of tokens.
     * @return Total supply.
     */
    function getSupply() external view returns (uint) {
        return tokenStorage.getSupply();
    }

    /**
     * @dev Returns the balance of an address.
     * @param who Address to lookup.
     * @return Number of units.
     */
    function getBalance(address who) external view returns (uint) {
        return tokenStorage.getBalance(who);
    }

    /**
     * @dev Returns the allowance for a spender.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @return Number of units.
     */
    function getAllowed(address owner, address spender)
        external
        view
        returns (uint)
    {
        return tokenStorage.getAllowed(owner, spender);
    }

}

// File: contracts/ERC20Lib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;


/**
 * @title ERC20Lib
 * @dev Standard ERC20 token functionality.
 * https://github.com/ethereum/EIPs/issues/20
 */
library ERC20Lib {

    using SafeMath for uint;

    /**
     * @dev Transfers tokens [ERC20].
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transfer(TokenStorage db, address caller, address to, uint amount)
        external
        returns (bool success)
    {
        db.subBalance(caller, amount);
        db.addBalance(to, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from a specific address [ERC20].
     * The address owner has to approve the spender beforehand.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to debet the tokens from.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transferFrom(
        TokenStorage db,
        address caller,
        address from,
        address to,
        uint amount
    )
        external
        returns (bool success)
    {
        uint allowance = db.getAllowed(from, caller);
        db.subBalance(from, amount);
        db.addBalance(to, amount);
        db.setAllowed(from, caller, allowance.sub(amount));
        return true;
    }

    /**
     * @dev Approves a spender [ERC20].
     * Note that using the approve/transferFrom presents a possible
     * security vulnerability described in:
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.quou09mcbpzw
     * Use transferAndCall to mitigate.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param spender The address of the future spender.
     * @param amount The allowance of the spender.
     */
    function approve(TokenStorage db, address caller, address spender, uint amount)
        public
        returns (bool success)
    {
        db.setAllowed(caller, spender, amount);
        return true;
    }

    /**
     * @dev Returns the number tokens associated with an address.
     * @param db Token storage to operate on.
     * @param who Address to lookup.
     * @return Balance of address.
     */
    function balanceOf(TokenStorage db, address who)
        external
        view
        returns (uint balance)
    {
        return db.getBalance(who);
    }

    /**
     * @dev Returns the allowance for a spender
     * @param db Token storage to operate on.
     * @param owner The address of the owner of the tokens.
     * @param spender The address of the spender.
     * @return Number of tokens the spender is allowed to spend.
     */
    function allowance(TokenStorage db, address owner, address spender)
        external
        view
        returns (uint remaining)
    {
        return db.getAllowed(owner, spender);
    }

}

// File: contracts/MintableTokenLib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;



/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

library MintableTokenLib {

    using SafeMath for uint;

    /**
     * @dev Mints new tokens.
     * @param db Token storage to operate on.
     * @param to The address that will recieve the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(
        TokenStorage db,
        address to,
        uint amount
    )
        external
        returns (bool)
    {
        db.addBalance(to, amount);
        return true;
    }

    /**
     * @dev Burns tokens.
     * @param db Token storage to operate on.
     * @param from The address holding tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        TokenStorage db,
        address from,
        uint amount
    )
        public
        returns (bool)
    {
        db.subBalance(from, amount);
        return true;
    }

    /**
     * @dev Burns tokens from a specific address.
     * To burn the tokens the caller needs to provide a signature
     * proving that the caller is authorized by the token owner to do so.
     * @param db Token storage to operate on.
     * @param from The address holding tokens.
     * @param amount The amount of tokens to burn.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     */
    function burn(
        TokenStorage db,
        address from,
        uint amount,
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (bool)
    {
        require(
            ecrecover(h, v, r, s) == from,
            "signature/hash does not match"
        );
        return burn(db, from, amount);
    }

}

// File: contracts/IValidator.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;

/**
 * @title IValidator
 * @dev Contracts implementing this interface validate token transfers.
 */
interface IValidator {

    /**
     * @dev Emitted when a validator makes a decision.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     * @param valid True if transfer approved, false if rejected.
     */
    event Decision(address indexed from, address indexed to, uint amount, bool valid);

    /**
     * @dev Validates token transfer.
     * If the sender is on the blacklist the transfer is denied.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     */
    function validate(address from, address to, uint amount) external returns (bool valid);

}

// File: contracts/SmartTokenLib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;



/**
 * @title SmartTokenLib
 * @dev This library provides functionality which is required from a regulatory perspective.
 */
library SmartTokenLib {

    using ERC20Lib for TokenStorage;
    using MintableTokenLib for TokenStorage;

    struct SmartStorage {
        IValidator validator;
    }

    /**
     * @dev Emitted when the contract owner recovers tokens.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     */
    event Recovered(address indexed from, address indexed to, uint amount);

    /**
     * @dev Emitted when updating the validator.
     * @param old Address of the old validator.
     * @param current Address of the new validator.
     */
    event Validator(address indexed old, address indexed current);

    /**
     * @dev Sets a new validator.
     * @param self Smart storage to operate on.
     * @param validator Address of validator.
     */
    function setValidator(SmartStorage storage self, address validator)
        external
    {
        emit Validator(self.validator, validator);
        self.validator = IValidator(validator);
    }


    /**
     * @dev Approves or rejects a transfer request.
     * The request is forwarded to a validator which implements
     * the actual business logic.
     * @param self Smart storage to operate on.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     */
    function validate(SmartStorage storage self, address from, address to, uint amount)
        external
        returns (bool valid)
    {
        return self.validator.validate(from, to, amount);
    }

    /**
     * @dev Recovers tokens from an address and reissues them to another address.
     * In case a user loses its private key the tokens can be recovered by burning
     * the tokens from that address and reissuing to a new address.
     * To recover tokens the contract owner needs to provide a signature
     * proving that the token owner has authorized the owner to do so.
     * @param from Address to burn tokens from.
     * @param to Address to mint tokens to.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     * @return Amount recovered.
     */
    function recover(
        TokenStorage token,
        address from,
        address to,
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint)
    {
        require(
            ecrecover(h, v, r, s) == from,
            "signature/hash does not recover from address"
        );
        uint amount = token.balanceOf(from);
        token.burn(from, amount);
        token.mint(to, amount);
        emit Recovered(from, to, amount);
        return amount;
    }

    /**
     * @dev Gets the current validator.
     * @param self Smart storage to operate on.
     * @return Address of validator.
     */
    function getValidator(SmartStorage storage self)
        external
        view
        returns (address)
    {
        return address(self.validator);
    }

}