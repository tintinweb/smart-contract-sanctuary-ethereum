import "./lib/fee/FeeSettingsBase.sol";
import "./lib/Ownable.sol";

contract FeeSettings is FeeSettingsBase, Ownable{}

import "../IOwnable.sol";
import "./IFeeSettings.sol";

abstract contract FeeSettingsBase is IFeeSettings, IOwnable {
    address _feeAddress;
    uint256 _feePercentil = 10;
    uint256 _feeEth = 1e16;

    constructor() {
        _feeAddress = msg.sender;
    }

    function feeAddress() external view returns (address) {
        return _feeAddress;
    }

    function feePercentil() external view returns (uint256) {
        return _feePercentil;
    }

    function feeEth() external view returns (uint256) {
        return _feeEth;
    }

    function setFeeAddress(address newFeeAddress) public onlyOwner {
        _feeAddress = newFeeAddress;
    }

    function setFeePercentil(uint256 newFeePercentil) external onlyOwner {
        require(newFeePercentil > 0 && newFeePercentil < 1000);
        _feePercentil = newFeePercentil;
    }

    function setFeeEth(uint256 newFeeEth) external onlyOwner {
        require(newFeeEth > 0);
        _feeEth = newFeeEth;
    }
}

import "./IOwnable.sol";

contract Ownable is IOwnable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() override {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

abstract contract IOwnable{
    modifier onlyOwner() virtual;
}

interface IFeeSettings{
    function feeAddress() external returns (address); // address to pay fee
    function feePercentil() external returns(uint256); // fee percentil for deviding values
    function feeEth() external returns(uint256); // fee value for not dividing deal points
}