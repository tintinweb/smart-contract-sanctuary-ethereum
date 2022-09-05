// SPDX-License-Identifier: UNLICENSED


//╱╱╱╭╮╭━━━┳━━━┳╮╱╱╱╱╭╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭╮╭━┳╮
//╱╱╱┃┃┃╭━╮┃╭━╮┃┃╱╱╱╭╯╰╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃┃┃╭┫┃
//╭━━┫┃┃┃┃┃┃┃┃┃┃┃╭┳━┻╮╭╯╭╮╱╭┳━━┳╮╭┳━┳━━┳━━┫┣╯╰┫┃
//┃━━┫┃┃┃┃┃┃┃┃┃┃┃┣┫━━┫┃╱┃┃╱┃┃╭╮┃┃┃┃╭┫━━┫┃━┫┣╮╭┻╯
//┣━━┃╰┫╰━╯┃╰━╯┃╰┫┣━━┃╰╮┃╰━╯┃╰╯┃╰╯┃┃┣━━┃┃━┫╰┫┃╭╮
//╰━━┻━┻━━━┻━━━┻━┻┻━━┻━╯╰━╮╭┻━━┻━━┻╯╰━━┻━━┻━┻╯╰╯
//╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
//╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯

pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";

contract sl00tlist is Owned {
    constructor()Owned(msg.sender){}

    mapping(address => bool) public sl00tlistStatus;
    bool public sl00tlistingEnabled = true;
    uint public balanceThreshold = 5e16;

    receive() external payable {
        sl00tlistYourself();
    }

    function sl00tlistYourself() public {
        require(msg.sender == tx.origin, "No contracts allowed");
        require(sl00tlistingEnabled, "Sl00tlisting is disabled");
        require(msg.sender.balance >= balanceThreshold, "Insufficient balance");
        sl00tlistStatus[msg.sender] = true;
    }

    function flipSl00tlisting() external onlyOwner {
        sl00tlistingEnabled = !sl00tlistingEnabled;
    }

    function updateThreshold(uint newThreshold) external onlyOwner {
        balanceThreshold = newThreshold;
    }

    function withdraw() external onlyOwner {
        assembly {
            let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
            switch result
            case 0 { revert(0, 0) }
            default { return(0, 0) }
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}