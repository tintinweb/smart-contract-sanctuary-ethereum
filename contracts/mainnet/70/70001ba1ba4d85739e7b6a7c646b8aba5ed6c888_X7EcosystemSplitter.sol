/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for balancing revenue across all revenue streams in the X7 system

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setWETH(address weth_) external onlyOwner {
        weth = weth_;
    }

    function setOutlet(Outlet outlet, address recipient) external onlyOwner {
        require(!isFrozen[outlet]);
        require(outletRecipient[outlet] != recipient);
        address oldRecipient = outletRecipient[outlet];
        outletLookup[recipient] = outlet;
        outletRecipient[outlet] = recipient;

        emit OutletRecipientSet(outlet, oldRecipient, recipient);
    }

    function freezeOutletChange(Outlet outlet) external onlyOwner {
        require(!isFrozen[outlet]);
        isFrozen[outlet] = true;

        emit OutletFrozen(outlet);
    }

    function setShares(uint256 x7rShare_, uint256 x7daoShare_, uint256 x7100Share_, uint256 lendingPoolShare_, uint256 treasuryShare_) external onlyOwner {
        require(treasuryShare_ >= treasuryMinShare);
        require(x7rShare_ + x7daoShare_ + x7100Share_ + lendingPoolShare_ + treasuryShare_ == 1000);
        require(x7rShare_ >= minShare && x7daoShare_ >= minShare && x7100Share_ >= minShare && lendingPoolShare_ >= minShare);
        require(x7rShare_ <= maxShare && x7daoShare_ <= maxShare && x7100Share_ <= maxShare && lendingPoolShare_ <= maxShare);

        outletShare[Outlet.X7R] = x7rShare_;
        outletShare[Outlet.X7DAO] = x7daoShare_;
        outletShare[Outlet.X7100] = x7100Share_;
        outletShare[Outlet.LENDING_POOL] = lendingPoolShare_;
        outletShare[Outlet.TREASURY] = treasuryShare_;

        emit SharesSet(x7rShare_, x7daoShare_, x7100Share_, lendingPoolShare_, treasuryShare_);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IX7EcosystemSplitter {
    function takeBalance() external;
}

contract X7EcosystemSplitter is Ownable, IX7EcosystemSplitter {

    enum Outlet {
        NONE,
        X7R,
        X7DAO,
        X7100,
        LENDING_POOL,
        TREASURY
    }

    mapping(Outlet => uint256) public outletBalance;
    mapping(Outlet => address) public outletRecipient;
    mapping(Outlet => uint256) public outletShare;
    mapping(address => Outlet) public outletLookup;
    mapping(Outlet => bool) public isFrozen;

    uint256 public minShare = 100;
    uint256 public maxShare = 500;

    uint256 public treasuryMinShare = 200;

    address public weth;

    event SharesSet(uint256 x7RShare, uint256 x7DAOShare, uint256 x7100Share, uint256 lendingPoolShare, uint256 treasuryShare);
    event OutletRecipientSet(Outlet outlet, address oldRecipient, address newRecipient);
    event OutletFrozen(Outlet outlet);

    constructor () Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        outletShare[Outlet.X7R] = 200;
        outletShare[Outlet.X7DAO] = 200;
        outletShare[Outlet.X7100] = 200;
        outletShare[Outlet.LENDING_POOL] = 200;
        outletShare[Outlet.TREASURY] = 200;

        emit SharesSet(200, 200, 200, 200, 200);
    }

    receive () external payable {
        outletBalance[Outlet.X7R] += msg.value * outletShare[Outlet.X7R] / 1000;
        outletBalance[Outlet.X7DAO] += msg.value * outletShare[Outlet.X7DAO] / 1000;
        outletBalance[Outlet.X7100] += msg.value * outletShare[Outlet.X7100] / 1000;
        outletBalance[Outlet.LENDING_POOL] += msg.value * outletShare[Outlet.LENDING_POOL] / 1000;
        outletBalance[Outlet.TREASURY] = address(this).balance - outletBalance[Outlet.X7R] - outletBalance[Outlet.X7DAO] - outletBalance[Outlet.X7100] - outletBalance[Outlet.LENDING_POOL];
    }

    function setWETH(address weth_) external onlyOwner {
        weth = weth_;
    }

    function setOutlet(Outlet outlet, address recipient) external onlyOwner {
        require(!isFrozen[outlet]);
        require(outletRecipient[outlet] != recipient);
        address oldRecipient = outletRecipient[outlet];
        outletLookup[recipient] = outlet;
        outletRecipient[outlet] = recipient;

        emit OutletRecipientSet(outlet, oldRecipient, recipient);
    }

    function freezeOutletChange(Outlet outlet) external onlyOwner {
        require(!isFrozen[outlet]);
        isFrozen[outlet] = true;

        emit OutletFrozen(outlet);
    }

    function setShares(uint256 x7rShare_, uint256 x7daoShare_, uint256 x7100Share_, uint256 lendingPoolShare_, uint256 treasuryShare_) external onlyOwner {
        require(treasuryShare_ >= treasuryMinShare);
        require(x7rShare_ + x7daoShare_ + x7100Share_ + lendingPoolShare_ + treasuryShare_ == 1000);
        require(x7rShare_ >= minShare && x7daoShare_ >= minShare && x7100Share_ >= minShare && lendingPoolShare_ >= minShare);
        require(x7rShare_ <= maxShare && x7daoShare_ <= maxShare && x7100Share_ <= maxShare && lendingPoolShare_ <= maxShare);

        outletShare[Outlet.X7R] = x7rShare_;
        outletShare[Outlet.X7DAO] = x7daoShare_;
        outletShare[Outlet.X7100] = x7100Share_;
        outletShare[Outlet.LENDING_POOL] = lendingPoolShare_;
        outletShare[Outlet.TREASURY] = treasuryShare_;

        emit SharesSet(x7rShare_, x7daoShare_, x7100Share_, lendingPoolShare_, treasuryShare_);
    }

    function takeBalance() external {
        Outlet outlet = outletLookup[msg.sender];
        require(outlet != Outlet.NONE);
        _sendBalance(outlet);
    }

    function _sendBalance(Outlet outlet) internal {
        if (outletRecipient[outlet] == address(0)) {
            return;
        }

        uint256 ethToSend = outletBalance[outlet];

        if (ethToSend > 0) {
            outletBalance[outlet] = 0;

            (bool success,) = outletRecipient[outlet].call{value: ethToSend}("");
            if (!success) {
                outletBalance[outlet] += ethToSend;
            }
        }
    }

    function pushAll() external {
        _sendBalance(Outlet.X7R);
        _sendBalance(Outlet.X7DAO);
        _sendBalance(Outlet.X7100);
        _sendBalance(Outlet.LENDING_POOL);
        _sendBalance(Outlet.TREASURY);
    }

    function rescueWETH() external {
        IWETH(weth).withdraw(IERC20(weth).balanceOf(address(this)));
    }

    function rescueTokens(address tokenAddress) external {
        IERC20(tokenAddress).transfer(outletRecipient[Outlet.TREASURY], IERC20(tokenAddress).balanceOf(address(this)));
    }
}