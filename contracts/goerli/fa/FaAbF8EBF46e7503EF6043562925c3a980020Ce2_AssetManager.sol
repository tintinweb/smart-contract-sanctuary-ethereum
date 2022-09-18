// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// author @erodactyl
contract AssetManager {
    event Issue(string name, address to, uint amount);

    struct AssetInfo {
        address creator;
        uint maxIssuance;
        uint price;
        string name;
        uint issued;
    }

    mapping(string => AssetInfo) public assets;

    mapping(string => mapping(address => uint)) public holders;

    function create(string calldata name, uint maxIssuance, uint price) external {
        require(assets[name].creator == address(0), "Asset name is taken");
        assets[name] = AssetInfo(msg.sender, maxIssuance, price, name, 0);
    }

    function buy(string calldata name, uint amount) external payable {
        AssetInfo storage info = assets[name];

        uint left = info.maxIssuance - info.issued;
        require(amount <= left, "Too many shares requested");

        require(msg.value >= amount * info.price, "Insufficient funds");

        info.issued += amount;
        holders[name][msg.sender] += amount;

        emit Issue(name, msg.sender, amount);

        payable(info.creator).transfer(msg.value);
    }

    function balanceOf(string calldata name) external view returns (uint) {
        return holders[name][msg.sender];
    }
}