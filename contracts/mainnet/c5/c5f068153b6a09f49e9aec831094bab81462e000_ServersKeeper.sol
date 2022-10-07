/**
 *Submitted for verification at Etherscan.io on 2022-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IMasterChefV1 {
    function withdraw(uint256 _pid, uint256 _amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;
}

interface IBridgeAdapter {
    function bridge() external;
}

abstract contract BaseServer is Ownable {
    IMasterChefV1 public constant masterchefV1 =
        IMasterChefV1(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    IERC20 public constant sushi =
        IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

    uint256 public immutable pid;

    address public immutable minichef;

    address public bridgeAdapter;

    event Harvested(uint256 indexed pid);
    event Withdrawn(uint256 indexed pid, uint256 indexed amount);
    event Deposited(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnSushi(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnDummyToken(uint256 indexed pid);
    event BridgeUpdated(address indexed newBridgeAdapter);

    constructor(uint256 _pid, address _minichef) {
        pid = _pid;
        minichef = _minichef;
        bridgeAdapter = address(this);
    }

    function harvestAndBridge() public {
        masterchefV1.withdraw(pid, 0);
        bridge();
        emit Harvested(pid);
    }

    function withdraw() public onlyOwner {
        masterchefV1.withdraw(pid, 1);
        emit Withdrawn(pid, 1);
    }

    function deposit(address token) public onlyOwner {
        IERC20(token).approve(address(masterchefV1), 1);
        masterchefV1.deposit(pid, 1);
        emit Deposited(pid, 1);
    }

    function withdrawSushiToken(address recipient) public onlyOwner {
        uint256 sushiBalance = sushi.balanceOf(address(this));
        sushi.transfer(recipient, sushiBalance);
        emit WithdrawnSushi(pid, sushiBalance);
    }

    function withdrawDummyToken(address token, address recipient)
        public
        onlyOwner
    {
        IERC20(token).transfer(recipient, 1);
        emit WithdrawnDummyToken(pid);
    }

    function updateBridgeAdapter(address newBridgeAdapter) public onlyOwner {
        require(newBridgeAdapter != address(0), "zero address");
        bridgeAdapter = newBridgeAdapter;
        emit BridgeUpdated(newBridgeAdapter);
    }

    function bridge() public {
        if (bridgeAdapter == address(this)) {
            _bridge();
        } else {
            uint256 sushiBalance = sushi.balanceOf(address(this));
            sushi.transfer(bridgeAdapter, sushiBalance);
            IBridgeAdapter(bridgeAdapter).bridge();
        }
    }

    function _bridge() internal virtual;
}

interface IMasterChef {
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract ServersKeeper is Ownable, KeeperCompatibleInterface {
    IMasterChef internal immutable masterchef;

    uint256 public minSushiAmount;

    address[] internal servers;

    constructor(address _masterchef, uint256 _minSushiAmount) {
        masterchef = IMasterChef(_masterchef);
        minSushiAmount = _minSushiAmount;
    }

    ///@notice Set the array of servers to be checked by the keeper
    function setServers(address[] calldata _servers) external onlyOwner {
        servers = _servers;
    }

    ///@notice Set the minimum sushi amount available to be harvested to execute a harvestAndBridge
    function setMinSushiAmount(uint256 newMinAmount) external onlyOwner {
        minSushiAmount = newMinAmount;
    }

    ///@notice View function checked by the keeper on every block
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 length = servers.length;
        for (uint256 i = 0; i < length; i++) {
            BaseServer server = BaseServer(servers[i]);
            if (
                masterchef.pendingSushi(server.pid(), servers[i]) >
                minSushiAmount
            ) {
                return (true, abi.encode(i));
            }
        }
    }

    ///@notice Function executed by the keeper if checkUpKeep returns true
    function performUpkeep(bytes calldata performData) external {
        uint256 serverId = abi.decode(performData, (uint256));
        BaseServer server = BaseServer(servers[serverId]);
        if (
            masterchef.pendingSushi(server.pid(), servers[serverId]) >
            minSushiAmount
        ) {
            server.harvestAndBridge();
        }
    }

    ///@notice Servers array getter
    function getServers() external view returns (address[] memory) {
        return servers;
    }
}