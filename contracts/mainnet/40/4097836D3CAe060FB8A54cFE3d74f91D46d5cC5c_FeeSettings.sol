pragma solidity ^0.8.17;
import '../lib/ownable/Ownable.sol';
import './IFeeSettings.sol';

contract FeeSettings is IFeeSettings, Ownable {
    address _feeAddress;
    uint256 _feePercent = 30; // 0.03%
    uint256 _maxFeePercent = 1000; // max fee is 1%
    uint256 _feeEth = 1e16;
    uint256 _maxFeeEth = 35e15; // max fixed eth fee is 0.035 eth

    constructor() {
        _feeAddress = msg.sender;
    }

    function feeAddress() external view returns (address) {
        return _feeAddress;
    }

    function feePercent() external view returns (uint256) {
        return _feePercent;
    }

    function feeDecimals() external view returns(uint256){
        return 100000;
    }

    function feeEth() external view returns (uint256) {
        return _feeEth;
    }

    function setFeeAddress(address newFeeAddress) public onlyOwner {
        _feeAddress = newFeeAddress;
    }

    function setFeePercent(uint256 newFeePercent) external onlyOwner {
        require(newFeePercent >= 0 && newFeePercent <= _maxFeePercent);
        _feePercent = newFeePercent;
    }

    function setFeeEth(uint256 newFeeEth) external onlyOwner {
        require(newFeeEth >= 0 && newFeeEth <= _maxFeeEth);
        _feeEth = newFeeEth;
    }
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/IOwnable.sol';

contract Ownable is IOwnable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
}

pragma solidity ^0.8.17;
interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

pragma solidity ^0.8.17;
interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}