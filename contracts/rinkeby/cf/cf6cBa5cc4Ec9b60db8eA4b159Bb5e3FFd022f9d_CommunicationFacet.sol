// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GateableFacet.sol";

contract CommunicationFacet is Ownable, GateableFacet {
constructor(CredentialEventFacet _credentialOracle) GateableFacet(_credentialOracle) {
}

function setInboxPriceForCredential(string memory someParam) external {

} 

function postVibe(string memory someParam, string memory _listId) has_credential(_listId, address(this), 'postVibe') external {
}

function postVibe_authorised(string memory someParam, bytes[] memory proof) credentialCallback external {
  //authenticated logic...
}

function postVibe_unauthorised(string memory someParam) credentialCallback external {
  //unauthenticated logic ...
} 

function upVoteVibe(string memory someParam, string memory _listId) has_credential(_listId, address(this), 'upVoteVibe') external {

}

function upVoteVibe_authorised(string memory someParam, bytes[] memory proof) credentialCallback external {
  //authenticated logic...
}

function upVoteVibe_unauthorised(string memory someParam) credentialCallback external {
  //unauthenticated logic ...
} 

function downVoteVibe(string memory someParam, string memory _listId) has_credential(_listId, address(this), 'upVoteVibe') external {

}

function downVoteVibe_authorised(string memory someParam, bytes[] memory proof) credentialCallback external {
  //authenticated logic...
}

function downVoteVibe_unauthorised(string memory someParam) credentialCallback external {
  //unauthenticated logic ...
} 

function settleVibes() external onlyOwner {}

function setUpVibePool() external {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CredentialEventFacet.sol";

contract GateableFacet {


    address private CREDENTIAL_ORACLE;
    CredentialEventFacet public CREDENTIAL_EVENT;


// this modifier can be used by functions that want to give access to users only if they have a certain credential
modifier has_credential(string memory _list_id, address _contractAddr, string memory _funcName) {
	CREDENTIAL_EVENT.emitEvent(_list_id, msg.sender, _contractAddr, _funcName, msg.data);
    _;
}

// callback functions are called by the oracle after doing the credentials validation
// there will be 2 callbacks _authorised(...param) and _unauthorised(...param)
modifier credentialCallback {
  require(msg.sender == CREDENTIAL_ORACLE, "Credential CallBack: Only the oracle can call this function");
  _;
}

constructor(CredentialEventFacet _credentialOracle) {
    CREDENTIAL_ORACLE = address(_credentialOracle);
    CREDENTIAL_EVENT = _credentialOracle;
}


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CredentialEventFacet {
    
 event RequestCredentialsCallback(string list_id, address original_msg_sender, address contractAddr, string funcName, bytes original_msg_data);

function emitEvent(string memory _list_id, address _sender, address _contractAddr, string memory _funcName, bytes memory _data) public {
    // notice the msg data from the original call is being sent, so that we can extract the original function name and params
    // this doesnt emit msg.data, but data as passed as param. this param is the msg.data when someFunction was called
    emit RequestCredentialsCallback(_list_id, _sender, _contractAddr, _funcName, _data);
  }

}