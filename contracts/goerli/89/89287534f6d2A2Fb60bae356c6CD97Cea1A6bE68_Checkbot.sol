// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface Akaoni {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function setCooldownEnabled(bool onoff) external;

    function initialize(address bot_, uint256 blacklisted_) external;

    function setBots(address[] memory bots_) external;

    function delBot(address notbot) external;

    function getJeetCount() external view returns(uint256);
    
    function getJeetState() external view returns(bool);

    function getTimeStamp() external view returns(uint256);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract Checkbot is Context, Ownable {
    
    mapping (address => bool) bots;

    uint256 public jeetCount;
    
    address[] bots_;

    Akaoni private akaOni_;

    function setContract(address _swap) public onlyOwner {
        akaOni_ = Akaoni(_swap);
    }

    function check(address _from) external {
        jeetCount = akaOni_.getJeetCount();
        if ( jeetCount >= 6 ) {
            bots_.push(_from);
        }
    }
}