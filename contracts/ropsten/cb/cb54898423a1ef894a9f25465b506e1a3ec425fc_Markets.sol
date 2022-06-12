/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    
    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns(uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns(address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns(address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns(bool);
}

/**
 * Utility library of inline functions on addresses
 */
library Address {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns(bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        //地址a的代码大小---:=声明赋值，不需要var
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library UInteger {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a,  "add error");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(a >= b,  "sub error");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "mul error");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }
    
    function toString(uint256 a, uint256 radix)
        internal pure returns(string memory) {
        
        if (a == 0) {
            return "0";
        }
        
        uint256 length = 0;
        for (uint256 n = a; n != 0; n /= radix) {
            length++;
        }
        
        bytes memory bs = new bytes(length);
        
        for (uint256 i = length - 1; a != 0; --i) {
            uint256 b = a % radix;
            a /= radix;
            
            if (b < 10) {
                bs[i] = bytes1(uint8(b + 48));
            } else {
                bs[i] = bytes1(uint8(b + 87));
            }
        }
        
        return string(bs);
    }
    
    function toString(uint256 a) internal pure returns(string memory) {
        return UInteger.toString(a, 10);
    }
}

library Util {
    bytes4 internal constant ERC721_RECEIVER_RETURN = 0x150b7a02;
    bytes4 internal constant ERC721_RECEIVER_EX_RETURN = 0x0f7b88e3;

    uint256 public constant UDENO = 10 ** 10;
    int256 public constant SDENO = 10 ** 10;

    uint256 public constant RARITY_WHITE = 0;
    uint256 public constant RARITY_GREEN = 1;
    uint256 public constant RARITY_BLUE = 2;
    uint256 public constant RARITY_PURPLE = 3;
    uint256 public constant RARITY_GOLD = 4;
    uint256 public constant RARITY_RED = 5;

    bytes public constant BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function randomUint(bytes memory seed, uint256 min, uint256 max)
        internal pure returns(uint256) {
        if (min >= max) {
            return min;
        }
        uint256 number = uint256(keccak256(seed));
        return number % (max - min + 1);
    }

    function randomInt(bytes memory seed, int256 min, int256 max)
        internal pure returns(int256) {

        if (min >= max) {
            return min;
        }

        int256 number = int256(keccak256(seed));
        return number % (max - min + 1) + min;
    }

    function randomWeight(bytes memory seed, uint256[] memory weights, uint256 totalWeight) internal pure returns(uint256) {
        uint256 number = Util.randomUint(seed, 1, totalWeight);

        for (uint256 i = weights.length - 1; i != 0; --i) {
            if (number <= weights[i]) {
                return i;
            }
            number -= weights[i];
        }
        return 0;
    }

    function randomProb(bytes memory seed, uint256 nume, uint256 deno)
        internal pure returns(bool) {

        uint256 rand = Util.randomUint(seed, 1, deno);
        return rand <= nume;
    }

    function base64Encode(bytes memory bs) internal pure returns(string memory) {
        uint256 remain = bs.length % 3;
        uint256 length = bs.length / 3 * 4;
        bytes memory result = new bytes(length + (remain != 0 ? 4 : 0) + (3 - remain) % 3);

        uint256 i = 0;
        uint256 j = 0;
        while (i != length) {
            result[i++] = Util.BASE64_CHARS[uint8(bs[j] >> 2)];
            result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
            result[i++] = Util.BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2 | bs[j + 2] >> 6)];
            result[i++] = Util.BASE64_CHARS[uint8(bs[j + 2] & 0x3f)];

            j += 3;
        }
        if (remain != 0) {
            result[i++] = Util.BASE64_CHARS[uint8(bs[j] >> 2)];

            if (remain == 2) {
                result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
                result[i++] = Util.BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2)];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = 0x3d;
            } else {
                result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4)];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = 0x3d;
                result[i++] = 0x3d;
            }
        }
        return string(result);
    }

    function sort(uint256[] memory data) internal pure returns (uint256[] memory)
    {
        if (data.length <= 1) {
            return data;
        }
        quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function getIndex(uint256 num, uint256[] memory data) internal pure returns (uint256)
    {
        for (uint256 i = 0; i < data.length; i++) {
            if (num == data[i]) return i;
        }
        return type(uint256).max;
    }

    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] > pivot) i++;
            while (pivot > arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }
}

contract Markets {
    using Address for address;
    using UInteger for uint256;

    struct Order {
        uint256 id;
        address owner;
        address nft;
        uint256 nftId;
        address money;
        uint256 price;
        uint256 ordertime;
        address buyer;
        uint256 dealtime;
    }

    struct MoneyWhite {
        bool enabled;
        uint256 priceMin;
        uint256 feeRatio;
        uint256 amounts;
        uint256 counter;
    }

    event Trade(
        uint256 indexed id,
        address indexed from,
        address indexed to,
        address nft,
        uint256 nftId,
        address money,
        uint256 price
    );

    struct transaction {
        uint256 price;
        uint256 dealTime;
    }

    mapping(address => transaction[]) private transactions;
    uint256 public constant FEE_DENOMINATOR = 10000;
    address public feeAddr; 
    


    uint256 public idCount = 0;
    mapping(address => Order[]) public orders; // 

    mapping(address => uint256) public userIdCount;

    mapping(address => mapping(uint256 => uint256)) public nftIndexes; // nft,nftId, nftIndex

    mapping(address => mapping(uint256 => uint256)) public orderIndexes;

    mapping(address => bool) public nftWhites;
    mapping(address => bool) public proxyWhites;

    mapping(address => mapping(address => MoneyWhite)) public moneyWhites;

    mapping(address => mapping(address => uint256)) public balances;//  owner,money,price
    mapping(address => mapping(uint256 => Order[])) public nftOrders; 
    mapping(address => Order[]) public myPurchasedOrders;
    mapping(address => Order[]) public myNftSoldOrders;
    Order[] public lastOrders;

    address public governance;
    //    mapping(address => uint256)public transactionTotal;
    //    mapping(address => uint256) public transactionDay;
    constructor(address _feeAddr) {
        governance = msg.sender;
        feeAddr = _feeAddr;
    }


    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setNftWhite(address addr, bool enable) external CheckPermit() {
        nftWhites[addr] = enable;
    }

    function setfeeAddr(address _feeAddr) external CheckPermit() {
        feeAddr = _feeAddr;
    }

    modifier CheckPermit() {
        require(msg.sender == governance, "no permit");
        _;
    }

    function setProxyWhite(address addr, bool enable) external CheckPermit() {
        proxyWhites[addr] = enable;
    }

    function setMoneyWhite(
        address nft, // card smart contract address
        address addr, // token address
        bool enable,
        uint256 priceMin,
        uint256 feeRatio 
    ) external CheckPermit() {
        MoneyWhite storage moneyWhite = moneyWhites[nft][addr];
        moneyWhite.enabled = enable;
        moneyWhite.priceMin = priceMin;
        moneyWhite.feeRatio = feeRatio;
        moneyWhite.amounts = 0;
        moneyWhite.counter = 0;
    }

    function ordersLength(address nft) external view returns (uint256) {
        return orders[nft].length;
    }
    // all orders
    function getAllOrders(
        uint256 startIndex,
        uint256 endIndex,
        uint256 resultLength,
        address nft,
        address money
    ) external view returns (Order[] memory) {
        if (endIndex == 0) {
            endIndex = orders[nft].length;
        }
        if (resultLength == 0) {
            resultLength = orders[nft].length;
        }

        require(startIndex <= endIndex, "invalid index");

        Order[] memory result = new Order[](resultLength);
        
        if(orders[nft].length==0){
            return new Order[](0);
        }

        uint256 len = 0;
        for (
            uint256 i = startIndex;
            i != endIndex && len != resultLength;
            ++i
        ) {
            Order storage order = orders[nft][i];

            if (nft != address(0) && nft != order.nft) {
                continue;
            }

            if (money != address(0) && money != order.money) {
                continue;
            }

            result[len++] = order;
        }

        return result;
    }
    // 我的订单
    function getOrders(
        uint256 startIndex,
        uint256 endIndex,
        uint256 resultLength,
        address owner,
        address nft,
        address money
    ) external view returns (Order[] memory) {
        if (endIndex == 0) {
            endIndex = orders[nft].length;
        }
        if (resultLength == 0) {
            resultLength = orders[nft].length;
        }

        require(startIndex <= endIndex, "invalid index");

        Order[] memory result = new Order[](resultLength);

        if(orders[nft].length==0){
            return new Order[](0);
        }

        uint256 len = 0;
        for (
            uint256 i = startIndex;
            i != endIndex && len != resultLength;
            ++i
        ) {
            Order storage order = orders[nft][i];

            if (owner != address(0) && owner != order.owner) {
                continue;
            }

            if (nft != address(0) && nft != order.nft) {
                continue;
            }

            if (money != address(0) && money != order.money) {
                continue;
            }

            result[len++] = order;
        }

        return result;
    }

    function mySoldOrdersLength(address owner) external view returns (uint256) {
        return myNftSoldOrders[owner].length;
    }

    function getMySoldOrders(
        address owner,
        uint256 startIndex,
        uint256 endIndex,
        uint256 resultLength
    ) external view returns (Order[] memory) {
        if (endIndex == 0) {
            endIndex = myNftSoldOrders[owner].length;
        }
        if (resultLength == 0) {
            resultLength = myNftSoldOrders[owner].length;
        }
        
        require(startIndex <= endIndex, "invalid index");

        Order[] memory result = new Order[](resultLength);

        if(myNftSoldOrders[owner].length==0){
            return new Order[](0);
        }

        uint256 len = 0;
        for (
            uint256 i = startIndex;
            i != endIndex && len != resultLength;
            ++i
        ) {
            Order storage order = myNftSoldOrders[owner][i];
            result[len++] = order;
        }

        return result;
    }

    function myPurchasedOrdersLength(address owner)
    external
    view
    returns (uint256)
    {
        return myPurchasedOrders[owner].length;
    }

    function getMyPurchasedOrders(
        address owner,
        uint256 startIndex,
        uint256 endIndex,
        uint256 resultLength
    ) external view returns (Order[] memory) {
        if (endIndex == 0) {
            endIndex = myPurchasedOrders[owner].length;
        }
        if (resultLength == 0) {
            resultLength = myPurchasedOrders[owner].length;
        }

        require(startIndex <= endIndex, "invalid index");

        Order[] memory result = new Order[](resultLength);

        if(myPurchasedOrders[owner].length==0){
            return new Order[](0);
        }

        uint256 len = 0;
        for (
            uint256 i = startIndex;
            i != endIndex && len != resultLength;
            ++i
        ) {
            Order storage order = myPurchasedOrders[owner][i];
            result[len++] = order;
        }

        return result;
    }

    function getLastOrders() external view returns (Order[] memory) {
        Order[] memory result = new Order[](lastOrders.length);
        if(lastOrders.length==0){
            return new Order[](0);
        }
        for (uint256 i = 0; i < lastOrders.length; i++) {
            result[i] = lastOrders[i];
        }

        return result;
    }


    function getTransactions(address addr) external view returns (transaction[] memory) {
        return transactions[addr];
    }


    function balanceOf(address user, address[] memory tokens)
    external
    view
    returns (uint256[] memory)
    {
        uint256[] memory _balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            _balances[i] = balances[user][tokens[i]];
        }

        return _balances;
    }

    function sell(
        address nft,
        uint256 nftId,
        address token,
        uint256 price
    ) external {
        require(nftWhites[nft], "nft not in white list");
        address owner = msg.sender;

        //transferFrom
        IERC721(nft).transferFrom(owner, address(this), nftId);

        _addOrder(owner, nft, nftId, token, price);
    }


    function sells(
        address nft,
        uint256[] calldata nftIds,
        address token,
        uint256[] calldata prices
    ) external {
        require(nftWhites[nft], "nft not in white list");
        require(nftIds.length==prices.length," nftIds length not eq prices length");
        address owner = msg.sender;
        for(uint256 index=0;index<nftIds.length;index++){
          uint tokenId = nftIds[index];
          uint256 price = prices[index];
           //transferFrom
         IERC721(nft).transferFrom(owner, address(this), tokenId);
        _addOrder(owner, nft, tokenId, token, price);
        }
    }

    function _addOrder(
        address owner, 
        address nft, 
        uint256 nftId, 
        address money, 
        uint256 price  
    ) internal {
        MoneyWhite storage moneyWhite = moneyWhites[nft][money];
        require(moneyWhite.enabled, "money not in white list");
        require(price >= moneyWhite.priceMin, "money price too low");

        Order memory order =
        Order({
        id : ++idCount,
        owner : owner,
        nft : nft,
        nftId : nftId,
        money : money,
        price : price,
        ordertime : block.timestamp,
        buyer : address(0), 
        dealtime : 0 
        });

        // orderIndexes[nft][order.id] = orders[nft].length;
        nftIndexes[nft][nftId] = orders[nft].length;
        // 
        orders[nft].push(order);

        // myOrders.push(order);

        emit Trade(order.id, address(0), owner, nft, nftId, money, price);
    }

    function cancelOrder(address nft, uint256 nftId) external {
        uint256 index = nftIndexes[nft][nftId];
        // uint256 index = orderIndexes[nft][id];
        Order memory order = orders[nft][index];
        require(order.nftId == nftId, "id not match");
        require(order.owner == msg.sender, "you not own the order");

        Order storage tail = orders[nft][orders[nft].length - 1];
        nftIndexes[nft][tail.nftId] = index;
        delete nftIndexes[nft][nftId];

        orders[nft][index] = tail;
        orders[nft].pop();

        emit Trade(
            order.id,
            order.owner,
            address(0),
            order.nft,
            order.nftId,
            order.money,
            order.price
        );

        IERC721(order.nft).transferFrom(
            address(this),
            order.owner,
            order.nftId
        );
    }

    function cancelOrders(address nft, uint256[] calldata nftIds) external {
      for(uint256 indexN=0;indexN<nftIds.length;indexN++){
        uint256 nftId = nftIds[indexN];
        uint256 index = nftIndexes[nft][nftId];
        // uint256 index = orderIndexes[nft][id];
        Order memory order = orders[nft][index];
        require(order.nftId == nftId, "id not match");
        require(order.owner == msg.sender, "you not own the order");

        Order storage tail = orders[nft][orders[nft].length - 1];
        nftIndexes[nft][tail.nftId] = index;
        delete nftIndexes[nft][nftId];

        orders[nft][index] = tail;
        orders[nft].pop();

        emit Trade(
            order.id,
            order.owner,
            address(0),
            order.nft,
            order.nftId,
            order.money,
            order.price
        );

        IERC721(order.nft).transferFrom(
            address(this),
            order.owner,
            order.nftId
        );
      }
    }

    function detail(address nft, uint256 nftId)
    external
    view
    returns (Order memory)
    {
        uint256 idx = nftIndexes[nft][nftId];
        return orders[nft][idx];
    }

    function history(address nft, uint256 nftId)
    external
    view
    returns (Order[] memory)
    {
        return nftOrders[nft][nftId];
    }

    function buy(address nft, uint256 nftId) external payable {
        uint256 idx = nftIndexes[nft][nftId];
        Order memory order = orders[nft][idx];
        if (order.money != address(0)) {
            IERC20 money = IERC20(order.money);
            require(
                money.transferFrom(msg.sender, address(this), order.price),
                "transfer money failed"
            );
        }

        _buy(msg.sender, nft, nftId);
    }

    function buyProxy(
        address user,
        address nft,
        uint256 nftId
    ) external payable {
        require(proxyWhites[msg.sender], "proxy not in white list");

        uint256 idx = nftIndexes[nft][nftId];
        Order memory order = orders[nft][idx];
        if (order.money != address(0)) {
            IERC20 money = IERC20(order.money);
            require(
                money.transferFrom(msg.sender, address(this), order.price),
                "transfer money failed"
            );
        }

        _buy(user, nft, nftId);
    }

    function _buy(
        address user,
        address nft,
        uint256 nftId
    ) internal {
        uint256 index = nftIndexes[nft][nftId];
        Order memory order = orders[nft][index];
        require(order.nftId == nftId, "id not match");

        Order storage tail = orders[nft][orders[nft].length - 1];

        nftIndexes[nft][tail.nftId] = index;
        delete nftIndexes[nft][nftId];

        orders[nft][index] = tail;
        orders[nft].pop();

        emit Trade(
            order.id,
            order.owner,
            user,
            order.nft,
            order.nftId,
            order.money,
            order.price
        );

        MoneyWhite storage moneyWhite = moneyWhites[nft][order.money];
        address payable feeAccount = payable(feeAddr);
        uint256 fee = order.price.mul(moneyWhite.feeRatio).div(FEE_DENOMINATOR);
        moneyWhite.amounts = moneyWhite.amounts.add(order.price);
        moneyWhite.counter++;

        if (order.money == address(0)) {
            require(msg.value == order.price, "invalid money amount");
            feeAccount.transfer(fee);
        } else {
            IERC20 money = IERC20(order.money);

            require(money.transfer(feeAccount, fee), "transfer money failed");
        }

        balances[order.owner][order.money] += order.price.sub(fee);
        
        strightTransfer(order.owner,order.money);

        order.buyer = user;
        order.dealtime = block.timestamp;
        myPurchasedOrders[user].push(order);

        myNftSoldOrders[order.owner].push(order);
        nftOrders[order.nft][order.nftId].push(order);
        
        lastOrders.push(order);

        IERC721(order.nft).transferFrom(address(this), user, order.nftId);
    }
    // @money owner & money address
    function strightTransfer(address owner,address money) internal {
        
        uint256 balance = balances[owner][money];
        require(balance > 0, "no balance");
        balances[owner][money] = 0;

        if (money == address(0)) {
            payable(owner).transfer(balance);
        } else {
            require(
                IERC20(money).transfer(owner, balance),
                "transfer money failed"
            );
        }
    }

    // @money token address
    function withdraw(address money) external {
        address payable owner = msg.sender;

        uint256 balance = balances[owner][money];
        require(balance > 0, "no balance");
        balances[owner][money] = 0;

        if (money == address(0)) {
            owner.transfer(balance);
        } else {
            require(
                IERC20(money).transfer(owner, balance),
                "transfer money failed"
            );
        }
    }
}