// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import '../params/Constructor.sol';
import '../../payments/params/MicroPayment.sol';
import '../../arenas/interfaces/IArenaFee.sol';
import '../../arenas/interfaces/IArenaCurrency.sol';
import '../params/Queue.sol';
import '../interfaces/IQueue.sol';

contract QueuesZerocost is Ownable {

    QueuesConstructor.Struct public control;
    constructor(QueuesConstructor.Struct memory input) {}

    function setGlobalParameters(QueuesConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
    }

    function enqueueCost(uint256 id) external view returns(
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory
    ) {

        Queue.Struct memory queue = IQueue(control.queues).queue(id);

        return (

            // Alpha Dune fee
            MicroPayment.Struct(
                queue.core.feeCurrency,
                ( queue.core.fee / queue.totalParticipants ) + queue.totalParticipants 
            ),

            // Arena fee 
            MicroPayment.Struct(
                IArenaCurrency(control.arenas).arenaCurrency(queue.core.arena),
                ( IArenaFee(control.arenas).arenaFee(queue.core.arena) / queue.totalParticipants ) + queue.totalParticipants + queue.core.entryFee
            ),

            // Entry fee 
            MicroPayment.Struct(
                queue.core.entryFeeCurrency,
                queue.core.entryFee
            )

        );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity 0.8.17;

library QueuesConstructor {
    struct Struct {

        // Contract modules
        address methods;
        address restricted;
        address queues;
        address zerocost;

        // External dependencies
        address arenas;
        address hounds;
        address payments;
        address races;
        address incubator;
        
        // Whitelist boilerplate
        address[] allowedCallers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library MicroPayment {
    
    struct Struct {
        address currency;
        uint256 amount;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Arena.sol';


interface IArenaFee {
    
    function arenaFee(uint256 theId) external view returns(uint256);
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Arena.sol';


interface IArenaCurrency {
    
    function arenaCurrency(uint256 theId) external view returns(address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';
import './Core.sol';
import '../../incubator/params/Specie.sol';

library Queue {
    
    struct Struct {

        Core.Struct core;

        uint256 startDate;

        uint256 endDate;

        uint256 lastCompletion;

        uint32 totalParticipants;

        uint32 cooldown;

        uint32 staminaCost;

        Specie.Enum[] speciesAllowed;

        bool closed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Queue.sol';


interface IQueue { 

    function queue(uint256 theId) external view returns(Queue.Struct memory);

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
pragma solidity 0.8.17;


library Arena {
    
    struct Struct {
        string name;
        string token_uri;

        address currency;
        uint256 fee;
        
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Payment {

    enum PaymentTypes {
        ERC721,
        ERC1155,
        ERC20,
        DEFAULT
    }
    
    struct Struct {
        address[] from;
        address[] to;
        address[] currency;
        uint256[][] ids;
        uint256[][] amounts;
        PaymentTypes[] paymentType;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';

library Core {
    
    struct Struct {

        string name;

        address feeCurrency;

        address entryFeeCurrency;

        uint256[] participants;

        uint256[] enqueueDates;

        uint256 arena;

        uint256 entryFee;

        uint256 fee;

        Payment.Struct payments;

    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Specie {
    enum Enum {
        FREE_HOUND,
        NORMAL,
        CHAD,
        RACER,
        COMMUNITY,
        SPEC_OPS,
        PRIME
    }
}