// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IEscrow.sol";
import "./IModerator.sol";

contract Escrow is IEscrow, Ownable {
    using SafeMath for uint256;
    //moderator contract
    address public moderatorAddress;

    IModerator moderatorContract;


    // total app num
    uint256 private maxAppNum;

    // app owner
    // appId => address
    mapping(uint256 => address) public appOwner;

    //how many seconds after order paid, can buyer make dispute
    // appId => interval
    mapping(uint256 => uint256) public appIntervalDispute;

    //how many seconds after order paid, can seller claim order
    // appId => interval
    mapping(uint256 => uint256) public appIntervalClaim;

    //how many seconds after dispute made, if seller does not response, buyer can claim the refund
    // appId => interval
    mapping(uint256 => uint256) public appIntervalRefuse;

    // app uri
    // appId => string
    mapping(uint256 => string) public appURI;

    // app name
    // appId => string
    mapping(uint256 => string) public appName;

    // app mod commission (For each mod and app owner if possible)
    mapping(uint256 => uint8) public appModCommission;

    // app owner commission
    mapping(uint256 => uint8) public appOwnerCommission;

    // modA resolution for order.
    // orderId => modA resolution : 0 not resolved, 1 agree refund, 2 disagree refund.
    mapping(uint256 => uint8) public orderModAResolution;

    // modB resolution for order.
    // orderId => modB resolution : 0 not resolved, 1 agree refund, 2 disagree refund.
    mapping(uint256 => uint8) public orderModBResolution;

    // total order num
    uint256 public maxOrderId;

    //Struct Order
    struct Order {
        uint256 appId; //app id
        uint256 amount; //order amount
        address coinAddress; //coin contract address
        address buyer; //buyer address
        address seller; //seller address
        uint256 createdTime; //order created timestamp
        uint256 claimTime; //timestamp after when seller can claim if there is no dispute
        uint8 status; //order status, 1 paid, 2 buyer ask refund, 3 completed, 4 seller refuse dispute, 5 buyer or seller escalate, so voters can vote
        uint256 modAId; //the mod that chosen by seller
    }

    // orderId => Order
    mapping(uint256 => Order) public orderBook;
    //Struct Dispute
    struct Dispute {
        uint256 refund; // refund amount
        uint256 modBId; // the mod that chosen by buyer
        uint256 refuseExpired; // after it, if seller does not refuse refund, buyer can claim the refund
    }

    // orderId => Dispute
    mapping(uint256 => Dispute) public disputeBook;

    // user balance (userAddress => mapping(coinAddress => balance))
    mapping(address => mapping(address => uint256)) public userBalance;

    //Withdraw event
    event Withdraw(
        address indexed user, //user wallet address
        uint256 indexed amount, //withdraw amount
        address indexed coinContract //withdraw coin contract
    );

    //Create new APP event
    event NewApp(uint256 indexed appId); //appId

    //Create order event
    event PayOrder(
        uint256 indexed orderId,
        uint256 indexed appOrderId,
        address indexed coinAddress,
        uint256 amount,
        address buyer,
        address seller,
        uint256 appId,
        uint256 modAId
    );

    //Confirm Done event
    event ConfirmDone(uint256 indexed appId, uint256 indexed orderId);

    //Ask refund event
    event AskRefund(
        uint256 indexed appId,
        uint256 indexed orderId,
        uint256 indexed refund
    );

    //Cancel refund event
    event CancelRefund(uint256 indexed appId, uint256 indexed orderId);

    //Refuse refund event
    event RefuseRefund(uint256 indexed appId, uint256 indexed orderId);

    //Escalate dispute event
    event Escalate(uint256 indexed appId, uint256 indexed orderId);

    //Resolve to Agree or Disagree refund
    event Resolve(
        address indexed user,
        bool indexed isAgree,
        uint256 indexed orderId,
        uint256 appId,
        uint8 modType // 0 both modA&modB, 1 modA, 2 modB, 3 app Owner 
    );

    //Resolved now event
    event ResolvedFinally(
        uint256 indexed appId,
        uint256 indexed orderId,
        uint8 indexed refundType //0 disagree win, 1 agree win, 2 seller refund
    );

    //Cash out event
    event Claim(
        address indexed user,
        uint256 indexed appId,
        uint256 indexed orderId
    );

    //User Balance Changed event
    event UserBalanceChanged(
        address indexed user,
        bool indexed isIn,
        uint256 indexed amount,
        address coinAddress,
        uint256 appId,
        uint256 orderId
    );

    constructor(address _modAddress) payable {
            moderatorAddress    =   _modAddress;
            moderatorContract   =  IModerator(_modAddress);

    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    receive() external payable {}

    function getModAddress() external view override returns (address)
    {
        return moderatorAddress;
    }

    // get total apps quantity
    function getTotalAppsQuantity() public view returns (uint256) {
        return maxAppNum;
    }

    // get app owner
    function getAppOwner(uint256 appId) public view returns (address) {
        return appOwner[appId];
    }

    //Create new APP
    function newApp(
        address _appOwner,
        string memory _appName,
        string memory websiteURI
    ) public onlyOwner returns (uint256) {
        uint256 appId = maxAppNum.add(1);
        appOwner[appId] = _appOwner;
        appURI[appId] = websiteURI;
        appName[appId] = _appName;
        appIntervalDispute[appId] = uint256(1000000);
        appIntervalClaim[appId] = uint256(1000000);
        appIntervalRefuse[appId] = uint256(86400);
        appModCommission[appId] = uint8(1);
        appOwnerCommission[appId] = uint8(1);
        maxAppNum = appId;
        emit NewApp(appId);

        return appId;
    }

    //Transfer app owner to a new address
    function setAppOwner(uint256 appId, address _newOwner)
        public
        returns (bool)
    {
        // Only app owner
        require(
            _msgSender() == appOwner[appId],
            "Escrow: only app owner can set app owner"
        );
        require(_newOwner != address(0), "Escrow: new owner is the zero address");
        appOwner[appId] = _newOwner;

        return true;
    }

    //Set mod commission
    //Only app owner
    function setModCommission(uint256 appId, uint8 _commission)
        public
        returns (bool)
    {
        // Only app owner
        require(
            _msgSender() == appOwner[appId],
            "Escrow: only app owner can set mod commission"
        );
        require(_commission < 15, "Escrow: commission must be less than 15");
        appModCommission[appId] = _commission;
        return true;
    }

    //Set app owner commission
    function setAppOwnerCommission(uint256 appId, uint8 _commission)
        public
        returns (bool)
    {
        // Only app owner
        require(
            _msgSender() == appOwner[appId],
            "Escrow: only app owner can set app owner commission"
        );
        require(_commission < 45, "Escrow: commission must be less than 45");
        appOwnerCommission[appId] = _commission;
        return true;
    }

    //Set dispute interval
    function setIntervalDispute(uint256 appId, uint256 _seconds)
        public
        returns (bool)
    {
        // Only app owner
        require(
            _msgSender() == appOwner[appId],
            "Escrow: only app owner can set dispute interval"
        );
        require(_seconds > 10, "Escrow: interval time too small!");
        require(_seconds < 10000000, "Escrow: interval time too big!");
        appIntervalDispute[appId] = _seconds;
        return true;
    }

    //Set refuse interval
    function setIntervalRefuse(uint256 appId, uint256 _seconds)
        public
        returns (bool)
    {
        // Only app owner
        require(
            _msgSender() == appOwner[appId],
            "Escrow: only app owner can set refuse interval"
        );
        require(_seconds > 10, "Escrow: interval time too small!");
        require(_seconds < 10000000, "Escrow: interval time too big!");
        appIntervalRefuse[appId] = _seconds;
        return true;
    }

    //Set claim interval
    function setIntervalClaim(uint256 appId, uint256 _seconds)
        public
        returns (bool)
    {
        // Only app owner
        require(
            _msgSender() == appOwner[appId],
            "Escrow: only app owner can set claim interval"
        );
        require(_seconds > 20, "Escrow: interval time too small!");
        require(_seconds < 10000000, "Escrow: interval time too big!");
        appIntervalClaim[appId] = _seconds;
        return true;
    }

    function getMaxModId() public view returns (uint256) {
       return moderatorContract.getMaxModId();
    }

    function getModOwner(uint256 modId) public view returns (address) {
        return moderatorContract.getModOwner(modId);
    }

    //Pay Order
    function payOrder(
        uint256 appId,
        uint256 amount,
        address coinAddress,
        address seller,
        uint256 appOrderId,
        uint256 modAId
    ) public payable returns (uint256) {
        require(
            appId > 0 &&
                appId <= maxAppNum &&
                appOrderId > 0 &&
                amount > 0,
                "Escrow: all the ids should be bigger than 0"
        );
        //Mod Id should be validated
        require(modAId <= moderatorContract.getMaxModId(), "Escrow: mod id is too big");
        //Native Currency
        if (coinAddress == address(0)) {
            require(msg.value == amount, "Escrow: Wrong amount or wrong value sent");
            //send native currency to this contract
            payable(this).transfer(amount);
        } else {
            IERC20 buyCoinContract = IERC20(coinAddress);
            //send ERC20 to this contract
            buyCoinContract.transferFrom(_msgSender(), address(this), amount);
        }
        maxOrderId = maxOrderId.add(1);
        // store order information
        Order memory _order;
        _order.appId = appId;
        _order.coinAddress = coinAddress;
        _order.amount = amount;
        _order.buyer = _msgSender();
        _order.seller = seller;
        _order.createdTime = block.timestamp;
        _order.claimTime = block.timestamp.add(appIntervalClaim[appId]);
        _order.status = uint8(1);
        _order.modAId = modAId;
        orderBook[maxOrderId] = _order;

        // emit event
        emit PayOrder(
            maxOrderId,
            appOrderId,
            coinAddress,
            amount,
            _msgSender(),
            seller,
            appId,
            modAId
        );

        return maxOrderId;
    }

    //confirm order received, and money will be sent to seller's balance
    //triggled by buyer
    function confirmDone(uint256 orderId) public {
        require(
            _msgSender() == orderBook[orderId].buyer,
            "Escrow: only buyer can confirm done"
        );

        require(
            orderBook[orderId].status == uint8(1) ||
                orderBook[orderId].status == uint8(2) ||
                orderBook[orderId].status == uint8(4),
            "Escrow: order status must be equal to just paid or refund asked or dispute refused"
        );

        // send money to seller's balance
        userBalance[orderBook[orderId].seller][
            orderBook[orderId].coinAddress
        ] = userBalance[orderBook[orderId].seller][
            orderBook[orderId].coinAddress
        ].add(orderBook[orderId].amount);
        emit UserBalanceChanged(
            orderBook[orderId].seller,
            true,
            orderBook[orderId].amount,
            orderBook[orderId].coinAddress,
            orderBook[orderId].appId,
            orderId
        );

        // set order status to completed
        orderBook[orderId].status == uint8(3);

        //emit event
        emit ConfirmDone(orderBook[orderId].appId, orderId);
    }

    //ask refund
    //triggled by buyer
    function askRefund(uint256 orderId, uint256 refund, uint256 modBId) public {
        require(
            _msgSender() == orderBook[orderId].buyer,
            "Escrow: only buyer can make dispute"
        );

        require(
            orderBook[orderId].status == uint8(1) ||
                orderBook[orderId].status == uint8(2),
            "Escrow: order status must be equal to just paid or refund asked"
        );

        require(
            block.timestamp < orderBook[orderId].createdTime.add(appIntervalDispute[orderBook[orderId].appId]),
            "Escrow: it is too late to make dispute"
        );

        require(refund > 0 && refund <= orderBook[orderId].amount, 
                "Escrow: refund amount must be bigger than 0 and not bigger than paid amount");

        require(
            modBId > 0 && modBId <= moderatorContract.getMaxModId(),
            "Escrow: modB id does not exists"
        );

        // update order status
        if (orderBook[orderId].status == uint8(1)) {
            orderBook[orderId].status = uint8(2);
        }
        // update refund of dispute
        disputeBook[orderId].refund = refund;
        // update modBId of dispute
        disputeBook[orderId].modBId = modBId;
        // update refuse expired
        disputeBook[orderId].refuseExpired = block.timestamp.add(appIntervalRefuse[orderBook[orderId].appId]);
        //emit event
        emit AskRefund(orderBook[orderId].appId, orderId, refund);
    }

    //cancel refund
    //triggled by buyer
    function cancelRefund(uint256 orderId) public {
        require(
            _msgSender() == orderBook[orderId].buyer,
            "Escrow: only buyer can cancel refund"
        );

        require(
            orderBook[orderId].status == uint8(2) ||
                orderBook[orderId].status == uint8(4),
            "Escrow: order status must be equal to refund asked or refund refused"
        );

        //update order status to paid
        orderBook[orderId].status = uint8(1);

        emit CancelRefund(orderBook[orderId].appId, orderId);
    }

    //refuse refund
    //triggled by seller
    function refuseRefund(uint256 orderId) public {
        require(
            _msgSender() == orderBook[orderId].seller,
            "Escrow: only seller can refuse dispute"
        );

        require(
            orderBook[orderId].status == uint8(2),
            "Escrow: order status must be equal to refund asked"
        );

        //update order status to refund refused
        orderBook[orderId].status = uint8(4);

        emit RefuseRefund(orderBook[orderId].appId, orderId);
    }

    //escalate, so mods can vote
    //triggled by seller or buyer
    function escalate(uint256 orderId) public {
        require(
            _msgSender() == orderBook[orderId].seller ||
                _msgSender() == orderBook[orderId].buyer,
            "Escrow: only seller or buyer can escalate"
        );

        require(
            orderBook[orderId].status == uint8(4),
            "Escrow: order status must be equal to refund refused by seller"
        );

        //update order status to escalate dispute, ready for mods to vote
        orderBook[orderId].status = uint8(5);

        emit Escalate(orderBook[orderId].appId, orderId);
    }

    // if seller agreed refund, then refund immediately
    // otherwise let mods or appOwner(if need) to judge
    
    function agreeRefund(uint256 orderId) public {
        //if seller agreed refund, then refund immediately
        if (_msgSender() == orderBook[orderId].seller) {
            require(
                orderBook[orderId].status == uint8(2) ||
                    orderBook[orderId].status == uint8(4) ||
                    orderBook[orderId].status == uint8(5),
                "Escrow: order status must be at refund asked or refund refused or dispute esclated"
            );
            sellerAgree(orderId);
        } else {
            require(
                orderBook[orderId].status == uint8(5),
                "Escrow: mod can only vote on dispute escalated status"
            );
            // get the mod's owner wallet address
            address modAWallet = moderatorContract.getModOwner(orderBook[orderId].modAId);
            address modBWallet = moderatorContract.getModOwner(disputeBook[orderId].modBId);
            // if modA's owner equal to modB's owner and they are msg sender
            if (
                modAWallet == modBWallet &&
                modAWallet == _msgSender()
            ) {
                // set modAResolution/modBResolution to voted
                orderModAResolution[orderId] = uint8(1);
                orderModBResolution[orderId] = uint8(1);
                resolvedFinally(orderId, true);
                emit Resolve(
                    _msgSender(),
                    true,
                    orderId,
                    orderBook[orderId].appId,
                    uint8(0)
                );
            }
            // if voter is app owner , and modA/modB not agree with each other.
            else if (
                appOwner[orderBook[orderId].appId] == _msgSender() &&
                ((orderModAResolution[orderId] == uint8(1) &&
                    orderModBResolution[orderId] == uint8(2)) ||
                    (orderModAResolution[orderId] == uint8(2) &&
                        orderModBResolution[orderId] == uint8(1)))
            ) {
                resolvedFinally(orderId, true);
                emit Resolve(
                    _msgSender(),
                    true,
                    orderId,
                    orderBook[orderId].appId,
                    uint8(3)
                );
            }
            // if voter is modA, and modA not vote yet, and modB not vote or vote disagree
            else if (
                modAWallet ==  _msgSender() &&
                orderModAResolution[orderId] == uint8(0) &&
                (orderModBResolution[orderId] == uint8(0) ||
                    orderModBResolution[orderId] == uint8(2))
            ) {
                // set modAResolution to voted
                orderModAResolution[orderId] = uint8(1);
                emit Resolve(
                    _msgSender(),
                    true,
                    orderId,
                    orderBook[orderId].appId,
                    uint8(1)
                );
            }
            // if voter is modA, and modA not vote yet, and modB vote agree
            else if (
                modAWallet == _msgSender() &&
                orderModAResolution[orderId] == uint8(0) &&
                orderModBResolution[orderId] == uint8(1)
            ) {
                // set modAResolution to voted
                orderModAResolution[orderId] = uint8(1);
                resolvedFinally(orderId, true);
                emit Resolve(
                    _msgSender(),
                    true,
                    orderId,
                    orderBook[orderId].appId,
                    uint8(1)
                );
            }
            // if voter is modB, and modB not vote yet, and modA not vote or vote disagree
            else if (
                modBWallet == _msgSender() &&
                orderModBResolution[orderId] == uint8(0) &&
                (orderModAResolution[orderId] == uint8(0) ||
                    orderModAResolution[orderId] == uint8(2))
            ) {
                // set modBResolution to voted
                orderModBResolution[orderId] = uint8(1);
                emit Resolve(
                    _msgSender(),
                    true,
                    orderId,
                    orderBook[orderId].appId,
                    uint8(2)
                );
            }
            // if voter is modB, and modB not vote yet, and modA vote agree
            else if (
                modBWallet == _msgSender() &&
                orderModBResolution[orderId] == uint8(0) &&
                orderModAResolution[orderId] == uint8(1)
            ) {
                // set modBResolution to voted
                orderModBResolution[orderId] = uint8(1);
                resolvedFinally(orderId, true);
                emit Resolve(
                    _msgSender(),
                    true,
                    orderId,
                    orderBook[orderId].appId,
                    uint8(2)
                );
            }
            // in other case , revert
            else {
                revert("Escrow: sender can not vote!");
            }
        }
    } 

    // the _msgSender() does not agree the refund
    
    function disagreeRefund(uint256 orderId) public {
        require(
            orderBook[orderId].status == uint8(5),
            "Escrow: mod can only vote on dispute escalated status"
        );
        // get the mod's owner wallet address
        address modAWallet = moderatorContract.getModOwner(orderBook[orderId].modAId);
        address modBWallet = moderatorContract.getModOwner(disputeBook[orderId].modBId);
        // if modA's owner equal to modB's owner and they are msg sender
        if (
            modAWallet == modBWallet && 
            modAWallet == _msgSender()
        ) {
            // set modAResolution/modBResolution to voted
            orderModAResolution[orderId] = uint8(2);
            orderModBResolution[orderId] = uint8(2);
            resolvedFinally(orderId, false);
            emit Resolve(
                _msgSender(), 
                false, 
                orderId, 
                orderBook[orderId].appId,
                uint8(0)
                );
        }
        // if voter is app owner , and modA/modB not agree with each other.
        else if (
            appOwner[orderBook[orderId].appId] == _msgSender() &&
            ((orderModAResolution[orderId] == uint8(2) &&
                orderModBResolution[orderId] == uint8(1)) ||
                (orderModAResolution[orderId] == uint8(1) &&
                    orderModBResolution[orderId] == uint8(2)))
        ) {
            resolvedFinally(orderId, false);
            emit Resolve(
                _msgSender(), 
                false, 
                orderId, 
                orderBook[orderId].appId,
                uint8(3)
                );
        }
        // if voter is modA, and modA not vote yet, and modB not vote or vote agree
        else if (
            modAWallet == _msgSender() &&
            orderModAResolution[orderId] == uint8(0) &&
            (orderModBResolution[orderId] == uint8(0) ||
                orderModBResolution[orderId] == uint8(1))
        ) {
            // set modAResolution to voted
            orderModAResolution[orderId] = uint8(2);
            emit Resolve(
                _msgSender(), 
                false, 
                orderId, 
                orderBook[orderId].appId,
                uint8(1)
                );
        }
        // if voter is modA, and modA not vote yet, and modB vote disagree
        else if (
            modAWallet == _msgSender() &&
            orderModAResolution[orderId] == uint8(0) &&
            orderModBResolution[orderId] == uint8(2)
        ) {
            // set modAResolution to voted
            orderModAResolution[orderId] = uint8(2);
            resolvedFinally(orderId, false);
            emit Resolve(
                _msgSender(), 
                false, 
                orderId, 
                orderBook[orderId].appId,
                uint8(1)
                );
        }
        // if voter is modB, and modB not vote yet, and modA not vote or vote agree
        else if (
            modBWallet == _msgSender() &&
            orderModBResolution[orderId] == uint8(0) &&
            (orderModAResolution[orderId] == uint8(0) ||
                orderModAResolution[orderId] == uint8(1))
        ) {
            // set modBResolution to voted
            orderModBResolution[orderId] = uint8(2);
            emit Resolve(
                _msgSender(), 
                false, 
                orderId, 
                orderBook[orderId].appId,
                uint8(2)
                );
        }
        // if voter is modB, and modB not vote yet, and modA vote disagree
        else if (
            modBWallet == _msgSender() &&
            orderModBResolution[orderId] == uint8(0) &&
            orderModAResolution[orderId] == uint8(2)
        ) {
            // set modBResolution to voted
            orderModBResolution[orderId] = uint8(2);
            resolvedFinally(orderId, false);
            emit Resolve(
                _msgSender(), 
                false, 
                orderId, 
                orderBook[orderId].appId,
                uint8(2)
                );
        }
        // in other case , revert
        else {
            revert("Escrow: sender can not vote!");
        }
    } 

    // if seller agreed refund, then refund immediately
    
    function sellerAgree(uint256 orderId) internal {
        require(_msgSender() == orderBook[orderId].seller);
        // update order status to finish
        orderBook[orderId].status = uint8(3);
        // final commission is the app owner commission
        uint8 finalCommission = appOwnerCommission[orderBook[orderId].appId];
        // add app ownner commission fee
        userBalance[appOwner[orderBook[orderId].appId]][orderBook[orderId].coinAddress] =
        userBalance[appOwner[orderBook[orderId].appId]][orderBook[orderId].coinAddress].add(
            orderBook[orderId].amount.mul(finalCommission).div(100));
        emit UserBalanceChanged(
                appOwner[orderBook[orderId].appId],
                true,
                orderBook[orderId].amount.mul(finalCommission).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
        // as the refund is approved, refund to buyer
        userBalance[orderBook[orderId].buyer][
            orderBook[orderId].coinAddress
        ] = userBalance[orderBook[orderId].buyer][
            orderBook[orderId].coinAddress
        ].add(disputeBook[orderId].refund.mul(100 - finalCommission).div(100));
        emit UserBalanceChanged(
            orderBook[orderId].buyer,
            true,
            disputeBook[orderId].refund.mul(100 - finalCommission).div(100),
            orderBook[orderId].coinAddress,
            orderBook[orderId].appId,
            orderId
        );
        // if there is amount left, then send left amount to seller
        if (orderBook[orderId].amount > disputeBook[orderId].refund) {
            userBalance[orderBook[orderId].seller][
                orderBook[orderId].coinAddress
            ] = userBalance[orderBook[orderId].seller][
                orderBook[orderId].coinAddress
            ].add(
                    (orderBook[orderId].amount.sub(disputeBook[orderId].refund))
                        .mul(100 - finalCommission)
                        .div(100)
                );
            emit UserBalanceChanged(
                orderBook[orderId].seller,
                true,
                (orderBook[orderId].amount.sub(disputeBook[orderId].refund))
                    .mul(100 - finalCommission)
                    .div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
        }
        emit ResolvedFinally(orderBook[orderId].appId, orderId, uint8(1));
    } 
    
    function resolvedFinally(uint256 orderId, bool result) internal {
        // update order status to finish
        orderBook[orderId].status = uint8(3);

        // the mod who judge right decision will increase 1 score, as well as adding the mod commission
        uint8 modNum = 1;
        uint8 winResolve = result ? 1 : 2;
        // get the mod's owner wallet address
        address modAWallet = moderatorContract.getModOwner(orderBook[orderId].modAId);
        address modBWallet = moderatorContract.getModOwner(disputeBook[orderId].modBId);
        // if modA's owner equal to modB's owner, then just increase 1 success score for the owner
        // and add the mod commission
        if (
            modAWallet == modBWallet
        ) {
            rewardMod(
                orderId,
                orderBook[orderId].modAId,
                modAWallet
            );
        }
        // else if modA does not agree with modB
        else if (orderModAResolution[orderId] != orderModBResolution[orderId]) {
            modNum = 2;
            // anyway app owner will get the mod commission
            userBalance[appOwner[orderBook[orderId].appId]][
                orderBook[orderId].coinAddress
            ] = userBalance[appOwner[orderBook[orderId].appId]][
                orderBook[orderId].coinAddress
            ].add(
                    orderBook[orderId]
                        .amount
                        .mul(appModCommission[orderBook[orderId].appId])
                        .div(100)
                );
            // the mod who vote the same as final result will give award
            if (orderModAResolution[orderId] == winResolve) {
                rewardMod(
                    orderId,
                    orderBook[orderId].modAId,
                    modAWallet
                );
                moderatorContract.updateModScore(disputeBook[orderId].modBId,false);
            } else {
                rewardMod(
                    orderId,
                    disputeBook[orderId].modBId,
                    modBWallet
                );
                moderatorContract.updateModScore(orderBook[orderId].modAId,false);
            }
        }
        // else if modA agree with modB
        else {
            // give both mods reward
            modNum = 2;
            rewardMod(
                orderId,
                orderBook[orderId].modAId,
                modAWallet
            );
            rewardMod(
                orderId,
                disputeBook[orderId].modBId,
                modBWallet
            );
        }
        // caculate the commission fee
        uint8 finalCommission = appOwnerCommission[orderBook[orderId].appId] +
            (modNum * appModCommission[orderBook[orderId].appId]);
        // send app owner commission fee
        userBalance[appOwner[orderBook[orderId].appId]][orderBook[orderId].coinAddress] =
        userBalance[appOwner[orderBook[orderId].appId]][orderBook[orderId].coinAddress].add(
            orderBook[orderId].amount.mul(appOwnerCommission[orderBook[orderId].appId]).div(100));
        emit UserBalanceChanged(
                appOwner[orderBook[orderId].appId],
                true,
                orderBook[orderId].amount.mul(appOwnerCommission[orderBook[orderId].appId]).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
        //if result is to refund, then refund to buyer, the left will be sent to seller
        //else all paid to the seller

        if (result == true) {
            // as the refund is approved, refund to buyer
            userBalance[orderBook[orderId].buyer][orderBook[orderId].coinAddress] = 
            userBalance[orderBook[orderId].buyer][orderBook[orderId].coinAddress].add(
                    disputeBook[orderId].refund.mul(100 - finalCommission).div(100));
            emit UserBalanceChanged(
                orderBook[orderId].buyer,
                true,
                disputeBook[orderId].refund.mul(100 - finalCommission).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
            // if there is amount left, then send left amount to seller
            if (orderBook[orderId].amount > disputeBook[orderId].refund) {
                userBalance[orderBook[orderId].seller][
                    orderBook[orderId].coinAddress
                ] = userBalance[orderBook[orderId].seller][
                    orderBook[orderId].coinAddress
                ].add(
                        (
                            orderBook[orderId].amount.sub(
                                disputeBook[orderId].refund
                            )
                        ).mul(100 - finalCommission).div(100)
                    );
                emit UserBalanceChanged(
                    orderBook[orderId].seller,
                    true,
                    (orderBook[orderId].amount.sub(disputeBook[orderId].refund))
                        .mul(100 - finalCommission)
                        .div(100),
                    orderBook[orderId].coinAddress,
                    orderBook[orderId].appId,
                    orderId
                );
            }
            emit ResolvedFinally(orderBook[orderId].appId, orderId, uint8(1));
        } else {
            // send all the amount to the seller
            userBalance[orderBook[orderId].seller][
                orderBook[orderId].coinAddress
            ] = userBalance[orderBook[orderId].seller][
                orderBook[orderId].coinAddress
            ].add(
                    orderBook[orderId].amount.mul(100 - finalCommission).div(
                        100
                    )
                );
            emit UserBalanceChanged(
                orderBook[orderId].seller,
                true,
                orderBook[orderId].amount.mul(100 - finalCommission).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
            emit ResolvedFinally(orderBook[orderId].appId, orderId, uint8(0));
        }
    }

    // reward mod
    // adding mod commission as well as increasing mod score
    
    function rewardMod(uint256 orderId, uint256 modId, address mod) private {
        moderatorContract.updateModScore(modId, true);
        userBalance[mod][orderBook[orderId].coinAddress] = 
        userBalance[mod][orderBook[orderId].coinAddress].add(
            orderBook[orderId].amount.mul(appModCommission[orderBook[orderId].appId]).div(100));
        emit UserBalanceChanged(
                mod,
                true,
                orderBook[orderId].amount.mul(appModCommission[orderBook[orderId].appId]).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
    } 

    //seller want to claim money from order to balance
    //or
    //buyer want to claim money after seller either not to refuse dispute or agree dispute
    
    function claim(uint256 orderId) public {
        // final commission is the app owner commission
        uint8 finalCommission = appOwnerCommission[orderBook[orderId].appId];
        // add app ownner commission fee
        userBalance[appOwner[orderBook[orderId].appId]][orderBook[orderId].coinAddress] =
        userBalance[appOwner[orderBook[orderId].appId]][orderBook[orderId].coinAddress].add(
            orderBook[orderId].amount.mul(finalCommission).div(100));
        emit UserBalanceChanged(
                appOwner[orderBook[orderId].appId],
                true,
                orderBook[orderId].amount.mul(finalCommission).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
        //seller claim
        if (_msgSender() == orderBook[orderId].seller) {
            require(
                orderBook[orderId].status == uint8(1),
                "Escrow: order status must be equal to 1 "
            );

            require(
                block.timestamp > orderBook[orderId].claimTime,
                "Escrow: currently seller can not claim, need to wait"
            );
            // send all the amount to the seller
            userBalance[orderBook[orderId].seller][
                orderBook[orderId].coinAddress
            ] = userBalance[orderBook[orderId].seller][
                orderBook[orderId].coinAddress
            ].add(
                    orderBook[orderId].amount.mul(100 - finalCommission).div(
                        100
                    )
                );
            emit UserBalanceChanged(
                orderBook[orderId].seller,
                true,
                orderBook[orderId].amount.mul(100 - finalCommission).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
            
        } else if (_msgSender() == orderBook[orderId].buyer) {
            // buyer claim

            require(
                orderBook[orderId].status == uint8(2),
                "Escrow: order status must be equal to 2 "
            );

            require(
                block.timestamp > disputeBook[orderId].refuseExpired,
                "Escrow: currently buyer can not claim, need to wait"
            );
            // refund to buyer
            userBalance[orderBook[orderId].buyer][orderBook[orderId].coinAddress] = 
            userBalance[orderBook[orderId].buyer][orderBook[orderId].coinAddress].add(
                    disputeBook[orderId].refund.mul(100 - finalCommission).div(100));
            emit UserBalanceChanged(
                orderBook[orderId].buyer,
                true,
                disputeBook[orderId].refund.mul(100 - finalCommission).div(100),
                orderBook[orderId].coinAddress,
                orderBook[orderId].appId,
                orderId
            );
            // if there is amount left, then send left amount to seller
            if (orderBook[orderId].amount > disputeBook[orderId].refund) {
                userBalance[orderBook[orderId].seller][
                    orderBook[orderId].coinAddress
                ] = userBalance[orderBook[orderId].seller][
                    orderBook[orderId].coinAddress
                ].add(
                        (
                            orderBook[orderId].amount.sub(
                                disputeBook[orderId].refund
                            )
                        ).mul(100 - finalCommission).div(100)
                    );
                emit UserBalanceChanged(
                    orderBook[orderId].seller,
                    true,
                    (orderBook[orderId].amount.sub(disputeBook[orderId].refund))
                        .mul(100 - finalCommission)
                        .div(100),
                    orderBook[orderId].coinAddress,
                    orderBook[orderId].appId,
                    orderId
                );
            }
            
        } else {
            revert("Escrow: only seller or buyer can claim");
        }

        orderBook[orderId].status = 3;
        emit Claim(_msgSender(), orderBook[orderId].appId, orderId);
    } 

    //withdraw from user balance
    function withdraw(uint256 _amount, address _coinAddress) public {
        //get user balance
        uint256 _balance = userBalance[_msgSender()][_coinAddress];

        require(_balance >= _amount, "Escrow: insufficient balance!");

        //descrease user balance
        userBalance[_msgSender()][_coinAddress] = _balance.sub(_amount);

        //if the coin type is ETH
        if (_coinAddress == address(0)) {
            //check balance is enough
            require(address(this).balance > _amount, "Escrow: insufficient balance");

            payable(_msgSender()).transfer(_amount);
        } else {
            //if the coin type is ERC20

            IERC20 _token = IERC20(_coinAddress);

            _token.transfer(_msgSender(), _amount);
        }

        //emit withdraw event
        emit Withdraw(_msgSender(), _amount, _coinAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModerator {
    
    // get mod's owner
    function getModOwner(uint256 modId) external view returns(address);

    // get mod's total supply
    function getMaxModId() external view returns(uint256);

    // update mod's score
    function updateModScore(uint256 modId, bool ifSuccess) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEscrow {
    function getModAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}