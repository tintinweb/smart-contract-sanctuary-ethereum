pragma solidity >=0.8.7;

import "../PointFactory.sol";
import "./EtherPoint.sol";

contract EtherPointFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        uint256 needCount,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(
                new EtherPoint(
                    address(swaper),
                    needCount,
                    from,
                    to,
                    swaper.feeAddress(),
                    swaper.feeEth()
                )
            )
        );
    }
}

pragma solidity >=0.8.7;

import "../ISwapper.sol"; 
import "../IDealPointFactory.sol";

abstract contract PointFactory is IDealPointFactory{
    ISwapper public swaper;
    mapping(address => uint256) public countsByCreator;
    uint256 countTotal;

    constructor(address routerAddress) {
        swaper = ISwapper(routerAddress);
    }

    function addPoint(uint256 dealId, address point) internal {
        ++countTotal;
        uint256 localCount = countsByCreator[msg.sender] + 1;
        countsByCreator[msg.sender] = localCount;
        swaper.addDealPoint(dealId, address(point));
    }
}

pragma solidity >=0.8.7;

import "../DealPoint.sol";

/// @dev эфировый пункт сделки
contract EtherPoint is DealPoint {
    uint256 public needCount;
    address public firstOwner;
    address public newOwner;
    uint256 public feeEth;

    constructor(
        address _router,
        uint256 _needCount,
        address _firstOwner,
        address _newOwner,
        address _feeAddress,
        uint256 _feeEth
    ) DealPoint(_router, _feeAddress) {
        router = _router;
        needCount = _needCount;
        firstOwner = _firstOwner;
        newOwner = _newOwner;
        feeEth = _feeEth;
    }

    function isComplete() external view override returns (bool) {
        return address(this).balance >= needCount;
    }

    function swap() external override {
        require(msg.sender == router);
        isSwapped = true;
    }

    function withdraw() external payable {
        if (isSwapped) {
            require(msg.value >= feeEth);
            payable(feeAddress).transfer(feeEth);
        }

        address owner = isSwapped ? newOwner : firstOwner;
        require(msg.sender == owner || msg.sender == router);
        payable(owner).transfer(address(this).balance);
    }
}

import "../fee/IFeeSettings.sol";

interface ISwapper is IFeeSettings{
    /// @dev добавляет в сделку пункт договора с указанным адресом
    /// данный метод может вызывать только фабрика
    function addDealPoint(uint256 dealId, address point) external;
}

import "./IDealPoint.sol";

interface IDealPointFactory{
}

interface IFeeSettings{
    function feeAddress() external returns (address); // address to pay fee
    function feePercentil() external returns(uint256); // fee percentil for deviding values
    function feeEth() external returns(uint256); // fee value for not dividing deal points
}

pragma solidity >=0.8.7;

interface IDealPoint{
    function isComplete() external view returns(bool); // выполнены ли условия
    function swap() external;   // свап
    function withdraw() external payable; // выводит средства владельца
}

import "../IDealPoint.sol";

abstract contract DealPoint is IDealPoint {
    address public router; // router has no specified type for testing reasons
    address feeAddress;
    bool public isSwapped;

    constructor(address _router, address _feeAddress) {
        router = _router;
        feeAddress = _feeAddress;
    }

    function swap() external virtual {
        require(msg.sender == router);
        isSwapped = true;
    }

    function isComplete() external view virtual returns (bool);
}