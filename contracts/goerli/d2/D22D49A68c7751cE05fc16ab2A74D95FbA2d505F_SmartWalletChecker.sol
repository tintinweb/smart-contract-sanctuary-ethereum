pragma solidity 0.8.10;

/***
 *@title SmartWalletChecker
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Whitelist manager for VotingEscrow
 */

import "./test/interfaces/dao/ISmartWalletChecker.sol";
import "./test/interfaces/pool/IOwnership.sol";

contract SmartWalletChecker is ISmartWalletChecker{

    IOwnership public immutable ownership;
    mapping(address => bool) whitelisted;

    modifier onlyOwner() {
        require(
            ownership.owner() == msg.sender,
            "Caller is not allowed to operate"
        );
        _;
    }

    constructor(address _ownership){
        ownership = IOwnership(_ownership);
    }

    function check(address _addr) external view returns (bool){
        /***
        * @notice check if the address is whitelisted or not
        * @param _addr address to check
        * @return bool true if passed address is whitelisted
        */

        return whitelisted[_addr];
    }

    function setWhitelist(address _target, bool _bool)external onlyOwner{
        /***
        * @notice set address's status. this can both set to and remove from whitelist
        * @param _target whitelisting address
        * @return _bool true when whitelisting the _target
        * @dev this is managed by DAO
        */

        whitelisted[_target] = _bool;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ISmartWalletChecker {
    function check(address _addr) external returns (bool);
}

pragma solidity 0.8.10;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}