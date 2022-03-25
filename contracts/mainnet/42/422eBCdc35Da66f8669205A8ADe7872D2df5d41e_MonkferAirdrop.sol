pragma solidity ^0.8.0;

interface IERC721 {
    function airdrop(address _to, uint256 _amount) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferOwnership(address newOwner) external;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() internal view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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

contract MonkferAirdrop is Ownable{

    IERC721 monkfer = IERC721(0xB2C1bec7BA2270269C259408cDAF818D28e6a5aB); //monkfer contract address
    constructor() {}

    function bulkAirdrops(address[] calldata _to, uint256[] calldata _amount) public {
        require(_to.length == _amount.length, "Receivers and amounts must be same length");
        for(uint256 i=0; i< _to.length; i++) {
            monkfer.airdrop(_to[i], _amount[i]);
        }
    }

    function changeMonkferOwnership(address _newOwner) public onlyOwner {
        monkfer.transferOwnership(_newOwner);
    }
}