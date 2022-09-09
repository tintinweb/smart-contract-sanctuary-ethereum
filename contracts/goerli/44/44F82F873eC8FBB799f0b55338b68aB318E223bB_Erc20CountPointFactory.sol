pragma solidity >=0.8.7;

import '../../PointFactory.sol';
import './Erc20CountPoint.sol';

contract Erc20CountPointFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        address token,
        uint256 needCount,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(
                new Erc20CountPoint(
                    address(swaper),
                    token,
                    needCount,
                    from,
                    to,
                    swaper.feeAddress(),
                    swaper.feePercent(),
                    swaper.feeDecimals()
                )
            )
        );
    }
}

pragma solidity >=0.8.7;

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

pragma solidity >=0.8.7;

import '../../DealPoint.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/// @dev позволяет создавать деталь сделки по трансферу ERC20 токена
contract Erc20CountPoint is DealPoint {
    IERC20 public token;
    uint256 public needCount;
    address public from;
    address public to;
    uint256 public feePercent;
    uint256 public feeDecimals;

    constructor(
        address _router,
        address _token,
        uint256 _needCount,
        address _from,
        address _to,
        address _feeAddress,
        uint256 _feePercent,
        uint256 _feeDecimals
    ) DealPoint(_router, _feeAddress) {
        router = _router;
        token = IERC20(_token);
        needCount = _needCount;
        from = _from;
        to = _to;
        feePercent = _feePercent;
        feeDecimals = _feeDecimals;
    }

    function isComplete() external view override returns (bool) {
        return token.balanceOf(address(this)) >= needCount;
    }

    function withdraw() external payable {
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        uint256 balance = token.balanceOf(address(this));
        uint256 fee = (balance * feePercent) / feeDecimals;
        if (!isSwapped) fee = 0;
        uint256 toTransfer = balance - fee;
        token.transfer(feeAddress, fee);
        token.transfer(owner, toTransfer);
    }
}

import '../fee/IFeeSettings.sol';
import './Deal.sol';

interface ISwapper is IFeeSettings {
    /// @dev добавляет в сделку пункт договора с указанным адресом
    /// данный метод может вызывать только фабрика
    function addDealPoint(uint256 dealId, address point) external;

    /// @dev возвращает сделку
    function getDeal(uint256 dealId) external view returns (Deal memory);
}

pragma solidity >=0.8.7;

import './IDealPoint.sol';

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner0; // owner 0 - creator
    address owner1; // owner 1 - second part
}

import './IDealPoint.sol';

interface IDealPointFactory {}

interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

pragma solidity >=0.8.7;

interface IDealPoint {
    function isComplete() external view returns (bool); // выполнены ли условия

    function swap() external; // свап

    function withdraw() external payable; // выводит средства владельца
}

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