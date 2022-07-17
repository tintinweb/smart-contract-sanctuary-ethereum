import "../lib/ownable/Ownable.sol";
import "./IFeeSettings.sol";

contract FeeSettings is IFeeSettings, Ownable {
    address _feeAddress;
    uint256 _feePercentil = 10;
    uint256 _maxFeePercentil = 10; // max fee is 1%
    uint256 _feeEth = 1e16;
    uint256 _maxFeeEth = 35e15; // max fixed eth fee is 0.035 eth

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
        require(newFeePercentil > 0 && newFeePercentil <= _maxFeePercentil);
        _feePercentil = newFeePercentil;
    }

    function setFeeEth(uint256 newFeeEth) external onlyOwner {
        require(newFeeEth > 0 && newFeeEth <= _maxFeeEth);
        _feeEth = newFeeEth;
    }
}

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

interface IFeeSettings{
    function feeAddress() external returns (address); // address to pay fee
    function feePercentil() external returns(uint256); // fee percentil for deviding values
    function feeEth() external returns(uint256); // fee value for not dividing deal points
}