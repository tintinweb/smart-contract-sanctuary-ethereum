pragma solidity ^0.8.17;

import '../PointFactory.sol';
import './EtherPoint.sol';

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

pragma solidity ^0.8.17;

import '../ISwapper.sol';
import '../Deal.sol';
import '../IDealPointFactory.sol';

abstract contract PointFactory is IDealPointFactory {
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
        Deal memory deal = swaper.getDeal(dealId);
        require(
            msg.sender == deal.owner0 || msg.sender == deal.owner1,
            'only owner can add the deal to dealPoint'
        );
        swaper.addDealPoint(dealId, address(point));
    }
}

pragma solidity ^0.8.17;

import '../DealPoint.sol';

/// @dev ether transaction point
contract EtherPoint is DealPoint {
    uint256 public needCount;
    address public firstOwner;
    address public newOwner;
    uint256 public feeEth;

    receive() external payable {}

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

pragma solidity ^0.8.17;
import '../fee/IFeeSettings.sol';
import './Deal.sol';

interface ISwapper is IFeeSettings {
    /// @dev adds a contract clause with the specified address to the deal
    /// this method can only be called by a factory
    function addDealPoint(uint256 dealId, address point) external;

    /// @dev returns the deal
    function getDeal(uint256 dealId) external view returns (Deal memory);
}

pragma solidity ^0.8.17;

import './IDealPoint.sol';

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner0; // owner 0 - creator
    address owner1; // owner 1 - second part
}

pragma solidity ^0.8.17;
import './IDealPoint.sol';

interface IDealPointFactory {}

pragma solidity ^0.8.17;
interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

pragma solidity ^0.8.17;

interface IDealPoint {
    function isComplete() external view returns (bool); // whether the conditions are met

    function swap() external; // swap

    function withdraw() external payable; // withdraws the owner's funds
}

pragma solidity ^0.8.17;
import '../IDealPoint.sol';

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