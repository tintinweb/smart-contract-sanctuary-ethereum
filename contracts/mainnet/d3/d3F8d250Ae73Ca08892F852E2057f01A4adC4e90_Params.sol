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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Params is Ownable {
    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ */

    string public checkPosition = "M266.931 50.132a2.424 2.424 0 0 0-2.072-1.163c-.877 0-1.646.465-2.071 1.163a2.433 2.433 0 0 0-2.29.642 2.428 2.428 0 0 0-.641 2.29 2.425 2.425 0 0 0-.001 4.144c-.098.404-.091.827.021 1.228a2.436 2.436 0 0 0 1.681 1.68c.401.114.824.121 1.229.022a2.422 2.422 0 0 0 2.999.98 2.43 2.43 0 0 0 1.145-.98 2.42 2.42 0 0 0 2.29-.641 2.428 2.428 0 0 0 .641-2.29 2.424 2.424 0 0 0 0-4.144 2.435 2.435 0 0 0-.021-1.228 2.435 2.435 0 0 0-1.681-1.681c-.4-.112-.823-.12-1.228-.022h-.001Zm-2.44 7.223 2.813-4.22c.349-.522-.463-1.064-.812-.542l-2.482 3.726-.846-.843c-.442-.445-1.132.244-.688.688l1.338 1.326a.483.483 0 0 0 .677-.136Z";
    string[] public colors = ['E84AA9','F2399D','DB2F96','E73E85','FF7F8E','FA5B67','E8424E','D5332F','C23532','F2281C','D41515','9D262F','DE3237','DA3321','EA3A2D','EB4429','EC7368','FF8079','FF9193','EA5B33','EB5A2A','ED7C30','EF9933','EF8C37','F18930','F09837','F9A45C','F2A43A','F2A840','F2A93C','FFB340','F2B341','FAD064','F7CA57','F6CB45','FFAB00','F4C44A','FCDE5B','F9DA4D','F9DA4A','FAE272','F9DB49','FAE663','FBEA5B','E2F24A','B5F13B','94E337','63C23C','86E48E','77E39F','83F1AE','5FCD8C','9DEFBF','2E9D9A','3EB8A1','5FC9BF','77D3DE','6AD1DE','5ABAD3','4291A8','45B2D3','81D1EC','33758D','A7DDF9','9AD9FB','2480BD','60B1F4','A4C8EE','4576D0','2E4985','3263D0','25438C','525EAA','3D43B3','322F92','4A2387','371471','3B088C','9741DA','6C31D7', '000000', '367A8F','4581EE','49788D','49A25E','7DE778','9CCF48','A0B3B7','AA2C5C','BB2891','C99C5F','D6D3CE','D97661','D97760','E04639','EB5D2D','ED6D8E','FCF153', 'F40A0A', 'FFFC34', '13EA42', '1400FF'];
    string[] public nogglePaths = ['d="M190.2 106v29.6H205h-44.4 14.8V106H86.6v29.6h14.8-59.2V180H57v-29.6h29.6v44.4h88.8v-44.4h14.8v44.4H279V106h-88.8Z"', 'd="M234.5 103.801c-20.5 0-37.8 13.3-44 31.6h-15.7c-6.2-18.4-23.5-31.6-44-31.6s-37.8 13.3-44 31.6H42.1v44.4h14.8v-29.6h27.6c0 25.6 20.8 46.4 46.4 46.4 25.6 0 46.4-20.8 46.4-46.4h10.9c0 25.6 20.8 46.4 46.4 46.4 25.6 0 46.4-20.8 46.4-46.4-.1-25.6-20.8-46.4-46.5-46.4Z"']; 
    string[] public gridPositions = ['x="86.56" y="105.76"','x="86.56" y="135.359"','x="86.56" y="164.959"','x="116" y="105.76"','x="116" y="135.359"','x="116" y="164.959"','x="145.44" y="105.76"','x="145.44" y="135.359"','x="145.44" y="164.959"','x="190.4" y="105.76"','x="190.4" y="135.359"','x="190.4" y="164.959"','x="219.84" y="105.76"','x="219.84" y="135.359"','x="219.84" y="164.959"','x="249.28" y="105.76"','x="249.28" y="135.359"','x="249.28" y="164.959"'];
    constructor() {}

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function setCheckPosition(string memory _checkPositition) external onlyOwner {
        checkPosition = _checkPositition;
    }

    function setCheckColors(string[] memory _colors) external onlyOwner {
        colors = _colors;
    }

    function setNogglePaths(string[] memory _nogglePaths) external onlyOwner {
        nogglePaths = _nogglePaths;
    }
    
    function setGridPositions(string[] memory _gridPositions) external onlyOwner {
        gridPositions = _gridPositions;
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           getter functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function getCheckPosition() external view returns (string memory) {
        return checkPosition;
    }

    function getColors() external view returns (string[] memory) {
        return colors;
    }

    function getNogglePaths() external view returns (string[] memory) {
        return nogglePaths;
    }

    function getGridPositions() external view returns (string[] memory) {
        return gridPositions;
    }    
}