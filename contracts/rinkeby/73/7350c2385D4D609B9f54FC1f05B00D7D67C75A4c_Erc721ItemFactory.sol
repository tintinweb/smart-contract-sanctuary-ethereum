pragma solidity >=0.8.7;

import "../../PointFactory.sol";
import "./Erc721ItemPoint.sol";

contract Erc721ItemFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        address token,
        uint256 itemId,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(
                new Erc721ItemPoint(
                    address(swaper),
                    token,
                    itemId,
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

import "../../DealPoint.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/// @dev позволяет создавать деталь сделки по трансферу ERC20 токена
contract Erc721ItemPoint is DealPoint {
    IERC721 public token;
    uint256 public itemId;
    address public from;
    address public to;
    uint256 public feeEth;

    constructor(
        address _router,
        address _token,
        uint256 _itemId,
        address _from,
        address _to,
        address _feeAddress,
        uint256 _feeEth
    ) DealPoint(_router, _feeAddress) {
        token = IERC721(_token);
        itemId = _itemId;
        from = _from;
        to = _to;
        feeEth = _feeEth;
    }

    function isComplete() external view override returns (bool) {
        return token.ownerOf(itemId) == address(this);
    }

    function withdraw() external payable {
        /*address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        token.transferFrom(address(this), owner, itemId);*/

        if (isSwapped) {
            require(msg.value >= feeEth);
            payable(feeAddress).transfer(feeEth);
        }

        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        uint256 count = token.balanceOf(address(this));
        for (uint256 i = 0; i < count; ++i) {
            token.transferFrom(
                address(this),
                owner,
                token.tokenOfOwnerByIndex(owner, 0)
            );
        }
    }
}

import "../lib/fee/IFeeSettings.sol";

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