pragma solidity ^0.8.17;

import '../../PointFactory.sol';
import './Erc721ItemPoint.sol';

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

import '../../DealPoint.sol';

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/// @dev allows to create a transaction detail for the transfer of ERC20 tokens
contract Erc721ItemPoint is DealPoint {
    IERC721 public token;
    uint256 public itemId;
    address public from;
    address public to;
    uint256 public feeEth;

    receive() external payable {}

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
        token.transferFrom(address(this), owner, itemId);
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