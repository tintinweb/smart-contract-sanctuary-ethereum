/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ERC20 {
    function name() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint);

    function owner() external view returns (address);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
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

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Airdropper is Ownable {
    event Airdrops(address token, address[] recipients, uint256 amount);

    struct SettingData {
        uint wage;
        address wageWallet;
        bool onmaintrance;
    }
    SettingData configs;

    constructor() {
        configs.wage = 1;
        configs.onmaintrance = false;
        configs.wageWallet = msg.sender;
    }

    function airdrops(
        address token,
        address[] memory recipients,
        uint256 amount
    ) public enable returns (bool) {
        (bool check, ) = address(token).call(abi.encodeWithSignature("name()"));
        address airdropowner = _msgSender();

        require(check, "Address not token contract!");
        require(recipients.length > 0, "Recipients list is empty!");
        require(amount > 0, "Amount is zero!");

        ERC20 tokencontract = ERC20(token);

        uint256 total = recipients.length * amount;
        uint wage = 0;

        if (configs.wage > 0) {
            wage = (total * configs.wage) / 1000;
            total += wage;
        }

        require(
            tokencontract.balanceOf(airdropowner) >= total,
            "Owner balance insufficient!"
        );

        require(
            tokencontract.allowance(airdropowner, address(this)) >= total,
            "Owner allowance not enough!"
        );

        tokencontract.transferFrom(airdropowner, address(this), total);
        require(
            tokencontract.balanceOf(address(this)) >= total,
            "Supply transfer failed!"
        );

        for (uint8 i; i < recipients.length; i++)
            tokencontract.transfer(recipients[i], amount);

        if (wage > 0) {
            tokencontract.transfer(configs.wageWallet, wage);
        }

        emit Airdrops(token, recipients, amount);

        return true;
    }

    function settlement(
        address token,        
        address to
    ) public enable onlyOwner returns (bool) {

		ERC20 tokencontract = ERC20(token);

        if (tokencontract.balanceOf(address(this)) > 0) {
            tokencontract.transfer(
                to,
                tokencontract.balanceOf(address(this))
            );
			return true;
        }
		return false;
    }

    modifier enable() {
        require(!configs.onmaintrance, "System On Maintrance!");

        _;
    }

    function getConfigs() public view returns (SettingData memory) {
        return configs;
    }

    function updateConfigs(SettingData memory newconfig)
        public
        onlyOwner
        returns (bool)
    {
        configs = newconfig;
        return true;
    }
}