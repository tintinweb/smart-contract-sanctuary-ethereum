/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor()  {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint256 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user 
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint256 expires) external ;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user 
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId 
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}



contract NFTRenting is Context {
    // Owner tạo cho thông tin cho thuê với 1 token nào đó
    struct RentalInfo{
        address owner;
        address tokenNFT;
        uint256 nftId;
        address paymentToken;
        uint256 price;
        uint256 period;
    }

    struct RentalRequest{
        RentalInfo rentalInfo;
        address user;
        uint256 timeUp; // time for the request exists
    }

    // Đang được owner cho thuê
    // rentId => RentalInfo
    mapping(string => RentalInfo) public tokensForRents;

    // rentId =>
    // mapping(string => RentalRequest[]) rentalRequests; ==> Không truy xuất được request của user với nft đó 
    mapping(string => mapping(address => RentalRequest)) public rentalRequests;
    // rentId => user
    // mapping(string => address[]) rentalRequestUsers;

   
    modifier onlyTokenOwner(address nft, uint256 tokenId){
        require(IERC721(nft).ownerOf(tokenId) == _msgSender(),"ERC721: you are not the NFT's owner");
        _;
    }

    modifier checkIsRented(string memory rentId){
        uint256 expireTime = IERC4907(tokensForRents[rentId].tokenNFT).userExpires(tokensForRents[rentId].nftId);
        // chưa thuê (expireTime = 0) hoặc hết hạn (expireTime < timestamp) => expireTIme < block.timestamp
        require (expireTime < uint256(block.timestamp), "NFTRenting: the NFT is being rented");
        _;
    }

    constructor(){         
   }

    function userOf(address tokenNFT, uint256 tokenId) public view returns(address){
        return IERC4907(tokenNFT).userOf(tokenId);
    }

    function userExpires(address tokenNFT, uint256 tokenId) public view returns(uint256){
        return IERC4907(tokenNFT).userExpires(tokenId);
    }

    // Owner tạo hoặc cập nhật thông tin cho thuê
    // onlyTokenOwner(tokenNFT, _tokenId) checkIsRented(rentId)
    function setForRent(string memory rentId, address tokenNFT, uint256 _tokenId, address paymentToken, uint256 price, uint256 period) public {
        tokensForRents[rentId] = RentalInfo(_msgSender(), tokenNFT, _tokenId, paymentToken, price, period);
        // emit UpdateForRent(tokenId, _msgSender(), price, period);   
    }

    // Owner huỷ thông tin cho thuê
    function cancelForRent(string memory rentId) public checkIsRented(rentId){
        require(tokensForRents[rentId].owner == msg.sender,"NFTRenting: You are not the owner");
        delete tokensForRents[rentId];
        // emit    
    }

    // User thuê (và chuyển tiền)
    //  checkIsRented(rentId)
    function rent(string memory rentId) public{
        RentalInfo memory info = tokensForRents[rentId];
        require(IERC20(info.paymentToken).transfer(info.owner, info.price), "ERC20: cannot pay money to the owner");
        IERC4907(info.tokenNFT).setUser(info.nftId, _msgSender(), uint256(block.timestamp) + info.period);

        // emit UserRent(tokenId, user);
    }   

    // User gửi request muốn thuê một NFT với thời gian request có hạn
    function requestForRent(string memory rentId, address tokenNFT, uint256 _tokenId, address paymentToken, uint256 price, uint256 period, uint256 timeUp) public {
        // require
        
        RentalInfo memory info   = RentalInfo(_msgSender(), tokenNFT, _tokenId, paymentToken, price, period);
        RentalRequest memory request = RentalRequest(info, _msgSender(), timeUp);
        rentalRequests[rentId][_msgSender()] = request;

        // Emit
    }

    function cancelRequestForRent(string memory rentId) public{
        // require
        require(rentalRequests[rentId][_msgSender()].user == _msgSender(), "NFTRenting: You are not the request owner");
        delete rentalRequests[rentId][_msgSender()] ;

        // Emit
    }

    function acceptRequest(string memory rentId, address user) public checkIsRented(rentId){
        // require
        
        RentalRequest memory request = rentalRequests[rentId][user];
        require(request.timeUp < block.timestamp,"NFTRenting: the request is time up");
        RentalInfo memory info  = request.rentalInfo;
        IERC4907(info.tokenNFT).setUser(info.nftId, user, uint256(block.timestamp) + info.period);

        // Emit
    }
}