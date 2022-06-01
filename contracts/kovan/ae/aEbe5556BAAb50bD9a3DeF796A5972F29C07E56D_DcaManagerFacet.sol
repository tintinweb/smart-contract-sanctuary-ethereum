// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "IERC20.sol";
import "AppStorage.sol";
import {DcaSettings} from "AppStorage.sol";

contract DcaManagerFacet {
    AppStorage internal s;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public owner;

    constructor() {
        owner = msg.sender;
        s.dcaManagerAddress = address(this);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setDaiAddress(address daiAddress) public onlyOwner {
        s.daiAddress = daiAddress;
    }

    function setWEthAddress(address wEthAddress) public onlyOwner {
        s.wEthAddress = wEthAddress;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function fundAccount(uint256 amount, address tokenAddress) public {
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) > amount,
            "Insuffisant balance"
        );
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        s.addressToDaiAmountFunded[msg.sender] += amount;
    }

    function withdraw(uint256 amount, address tokenAddress) public {
        require(
            s.addressToDaiAmountFunded[msg.sender] > 0,
            "Account no funded"
        );
        IERC20(tokenAddress).transfer(msg.sender, amount);
        s.addressToDaiAmountFunded[msg.sender] = 0;
    }

    /*
    DAILY = 86400,
    BI_WEEKLY 302400,
    WEEKLY = 604800,
    MONTHLY = 2592000
    */
    function setDcaSettings(DcaSettings memory dcaSettings) public {
        require(
            s.addressToDaiAmountFunded[msg.sender] > 0,
            "Account not funded"
        );
        require(
            dcaSettings.period == 86400 ||
                dcaSettings.period == 302400 ||
                dcaSettings.period == 604800 ||
                dcaSettings.period == 2592000,
            "DcaManager: Invalid interval"
        );
        s.addressToDcaSettings[msg.sender] = dcaSettings;
    }

    function approveKeeper() public onlyOwner {
        IERC20(s.daiAddress).approve(s.dcaKeeperAddress, uint256(-1));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

struct DcaSettings {
    uint256 amount;
    uint256 period;
}

struct GlobalSettings {
    address dcaManagerAddress;
    address dcaKeeperAddress;
    address daiAddress;
    address wEthAddress;
}

struct AppStorage {
    address dcaManagerAddress;
    address dcaKeeperAddress;
    address daiAddress;
    address wEthAddress;
    address uniSwapRouterAddress;
    mapping(address => uint256) addressToDaiAmountFunded;
    mapping(address => DcaSettings) addressToDcaSettings;
    GlobalSettings globalSettings;
}