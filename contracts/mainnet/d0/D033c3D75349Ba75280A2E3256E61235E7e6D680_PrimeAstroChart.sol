// contracts/AstroChart.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseOraclizedAstroChart.sol";

contract PrimeAstroChart is BaseOraclizedAstroChart {
    event AstroChartBred(uint256 bredTokenId, uint256 fromTokenId, address bredTokenOwner, uint256 price);

    constructor(address _svgGeneratorAddress) ERC721("meta-astro-genesis", "P-ASTRO") {
        AstroChartLib._initNextTokenId(1);
        _transferOwnership(_msgSender());
        svgGenerator = SVGGenerator(_svgGeneratorAddress);
    }

    ///
    /// setUpParams used by MetaAstro ERC-721 Token
    /// @param linkTokenAddress, Chainlink's ERC-20 token address,
    /// @param _oracle, oracle address
    /// @param _jobId, oracle jobId used to calculate astro data
    /// @param _feeInLink, fee that should paid to Oracle operator for each request
    /// @param _oracleGasFee, gas fee that operator use when submit data back to contract
    /// @param _oracleRequestHost, host for oracle operator node to send request to
    /// @param _salesStartTime, initial mint start time
    /// @param _salesEndTime, initial mint end time
    ///
    function setUpParams(
        address linkTokenAddress,
        address _oracle,
        bytes32 _jobId,
        uint256 _feeInLink,
        uint256 _oracleGasFee,
        string calldata _oracleRequestHost,
        uint256 _salesStartTime,
        uint256 _salesEndTime,
        SVGGenerator _svgGenerator
    ) external onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
        fee = _feeInLink;
        oracleRequestHost = _oracleRequestHost;
        setChainlinkToken(linkTokenAddress);
        AstroChartLib.setOracleGasFee(_oracleGasFee);
        AstroChartLib.setSalesTimes(_salesStartTime, _salesEndTime);
        svgGenerator = _svgGenerator;
    }

    /**
    withdraw initial deposit, only can be done by owner
    require amount <= initialDeposit, or else throw "withdraw amount must less than initialDeposit" as WAMLTI
     */
    function withdrawInitialDeposit(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    /**
    initial mint,
    require initialMintCount < INITIAL_MINT_LIMIT, or else throw "initial mint limit arrived" as "IMLA"
    require msg.value >= getPrice() + oracleGasFee, or else throw "initial mint should pay with initialMintPrice + oracleGasFee" as "IMSPWI+O"
    require salesStartTime > 0 && currentTimeOffset >= salesStartTime, or else throw sales not start as "SNS"
    require libStorage().initialMintDate2Exists[dateToBytes32(datetimeOfBirth)] == false, or else throw initial mint date already exists as "IMDAE"
    _checkForDateAndCity's rule, ref _checkForDateAndCity's comment
     */
    function initialMint(
        address to,
        uint16[] calldata monthAndDay,
        string calldata remaining
    ) external payable {
        uint256 tokenId = AstroChartLib.initialMintDry(monthAndDay, remaining);
        _safeMint(to, tokenId);

        //interactions
        sendRequestToOracle(tokenId, monthAndDay, remaining);
    }

    /**
    regenerate,
    require onwerOf(tokenId) == msg.sender, or else throw "token not owned by sender" as "TNOBS"
    require msg.value >= oracleGasFee, or else throw "regenerate should pay with oracleGasFee" as "RSPWO"
    require monthAndDay == token.originAstroArgs.monthAndDay, or else throw "Month and day should equal to origin" as "MDSETO" 
    require monthAndDay.length == 2 and monthAndDay is valid or else throw "datetime not valid" as "DTNV"
     */
    function regenerate(
        uint256 tokenId,
        uint16[] calldata monthAndDay,
        string calldata remaining
    ) external payable {
        AstroChartLib.regenerateDry(tokenId, ownerOf(tokenId), monthAndDay, remaining);
        sendRequestToOracle(tokenId, monthAndDay, remaining);
    }

    function beginNoDateLimitMint() public onlyOwner {
        AstroChartLib.beginNoDateLimitPrimeMint();
    }

    function isNoDateLimitMintBegan() public view returns (bool) {
        return AstroChartLib.isNoDateLimitPrimeMintBegan();
    }

    function initalMintCount() external view returns (uint256) {
        return AstroChartLib.initialMintCount();
    }

    function initialDeposit() external view returns (uint256) {
        return AstroChartLib.initialDeposit();
    }

    function getPrice() external view returns (uint256) {
        return AstroChartLib.getPrice();
    }

    function getSalesTimes() external view returns (uint256, uint256) {
        return AstroChartLib.getSalesTimes();
    }

    function getAstroArgsOf(uint256 tokenId) external view returns (AstroChartArgs memory) {
        return AstroChartLib.getAstroArgsOf(tokenId);
    }

    function getPendingWithdraw() external view returns (uint256) {
        return AstroChartLib.getPendingWithdraw();
    }

    ///
    /// return relative prime tokenId if exist, orelse return 0
    function getTokenIdByMonthAndDay(uint16 month, uint16 day) external view returns (uint256) {
        return AstroChartLib.getTokenIdByMonthAndDay(month, day);
    }

    /**
    ERC-721 tokenURI 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenURIOf(tokenId, tokenId);
    }
}

// contracts/AstroChart.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./libraries/OracleUtils.sol";
import "./libraries/SVGGenerator.sol";
import "./libraries/AstroChartLib.sol";

abstract contract BaseOraclizedAstroChart is ERC721Enumerable, Ownable, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    /***
     * ChainLink Block start
     */
    address internal oracle;

    bytes32 internal jobId;

    uint256 internal fee;

    string internal oracleRequestHost;

    SVGGenerator internal svgGenerator;

    mapping(bytes32 => AstroChartResponse) internal request2Response;

    struct AstroChartResponse {
        uint16[] cusps;
        uint16[] planets;
        bool exists;
    }

    /**
     * ChainLink Block end
     */

    // record tokenId to oracle request id
    mapping(uint256 => bytes32) public tokenId2OracleRequestId;

    /**
     Chainlink Relative Block start!!!!
     */
    function getLinkTokenAddress() external view returns (address) {
        return chainlinkTokenAddress();
    }

    /**
    Use to withdraw remain link from contract
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function sendRequestToOracle(
        uint256 tokenId,
        uint16[] memory monthAndDay,
        string memory remaining
    ) internal returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        string memory url = OracleUtils.genRequestURL(oracleRequestHost, monthAndDay, remaining);

        // Set the URL to perform the GET request on
        request.add("get", url);
        request.add("path_cusps", "cusps");
        request.add("path_planets", "planets");

        // Sends the request
        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);

        tokenId2OracleRequestId[tokenId] = requestId;

        return requestId;
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        uint16[] calldata _cusps,
        uint16[] calldata _planets
    ) external recordChainlinkFulfillment(_requestId) {
        request2Response[_requestId] = AstroChartResponse({cusps: _cusps, planets: _planets, exists: true});
    }

    /**
    Chainlink Relative Block end!!!
     */

    function tokenURIOf(uint256 tokenId, uint256 gen0RootTokenId) internal view returns (string memory) {
        bytes32 requestId = tokenId2OracleRequestId[tokenId];
        require(requestId != "0x0", "Token not minted");

        AstroChartResponse memory response = request2Response[requestId];

        if (!response.exists) {
            return svgGenerator.nonExistSVGInOpenSeaFormat(tokenId, gen0RootTokenId);
        } else {
            AstroChartArgs memory args = AstroChartLib.getAstroArgsOf(tokenId);
            return
                svgGenerator.genSVGInOpenSeaFormat(
                    response.cusps,
                    response.planets,
                    args.generation,
                    tokenId,
                    args.monthAndDay[0],
                    args.monthAndDay[1],
                    gen0RootTokenId
                );
        }
    }

    function getResponseOf(uint256 tokenId) public view returns (AstroChartResponse memory) {
        bytes32 requestId = tokenId2OracleRequestId[tokenId];
        return request2Response[requestId];
    }

    function getOracleGasFee() public view returns (uint256) {
        return AstroChartLib.getOracleGasFee();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./StringLib.sol";

library OracleUtils {
    function genRequestURL(
        string memory oracleRequestHost,
        uint16[] memory monthAndDay,
        string memory remaining
    ) internal pure returns (string memory url) {
        url = string(
            abi.encodePacked(
                oracleRequestHost,
                "/api/v1/calc-chart-data-degrees-encrypted?houses=Placidus&zodiac=Krishnamurti&monthAndDay=",
                convertDatetimeToString(monthAndDay),
                "&remaining=",
                remaining
            )
        );
    }

    function convertDatetimeToString(uint16[] memory datetime)
        private
        pure
        returns (string memory res)
    {
        uint16 month = datetime[0];
        uint16 day = datetime[1];

        res = string(
            abi.encodePacked(
                StringLib.uintToString(month),
                ",",
                StringLib.uintToString(day)
            )
        );
    }
}

// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "xp-math/contracts/xpmath.sol";
import "./Base64.sol";
import "./StringLib.sol";

import "./FireGenerator.sol";
import "./FireGenerator2.sol";

contract SVGGenerator {
    int128 private constant OVERLAP_DETECT = 1200; //number in rad*1000
    uint16 private constant SPACE_RAD = 1300;
    int128 private constant PRECISION = 10000; //4 decimals
    uint16 private constant DOWN60 = 9599;
    uint16 private constant UP60 = 11344;
    uint16 private constant DOWN90 = 14486;
    uint16 private constant UP90 = 16929;
    uint16 private constant DOWN120 = 19897;
    uint16 private constant UP120 = 21991;
    uint16 private constant DOWN180 = 30194;
    uint16 private constant UP180 = 32637;

    enum LineColor {
        Red,
        Green,
        Blue,
        Yellow,
        Default
    }

    FireGenerator private fireGenerator;

    constructor(FireGenerator _fireGenerator) {
        fireGenerator = _fireGenerator;
    }

    function nonExistSVGInOpenSeaFormat(uint256 tokenId, uint256 rootGen0TokenId)
        public
        pure
        returns (string memory)
    {
        string
            memory output = '<svg width="600" height="600" xmlns="http://www.w3.org/2000/svg"><text id="svg_6" font-size="10" y="311" x="301">generating...</text><svg>';
        return encodeInSVGFormat(output, tokenId, rootGen0TokenId, 0, 0, 0);
    }

    function genSVGInOpenSeaFormat(
        uint16[] memory cusps,
        uint16[] memory planets,
        uint32 generation,
        uint256 tokenId,
        uint16 month,
        uint16 day,
        uint256 rootGen0TokenId
    ) public view returns (string memory) {
        string memory output = soGenSVG(cusps, planets, generation, month, day);
        return encodeInSVGFormat(output, tokenId, rootGen0TokenId, generation, month, day);
    }

    function encodeInSVGFormat(string memory _rawSVG, uint256 tokenId, uint256 rootGen0TokenId, uint32 generation, uint16 month, uint16 day)
        private
        pure
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Meta Astrology Chart #',
                        StringLib.uintToString(tokenId),
                        '", "description": "metaverse on-chain astro chart", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_rawSVG)),
                        '", "attributes": [{"trait_type": "rootGen0TokenId", "value": "',
                        StringLib.uintToString(rootGen0TokenId),
                        '"}, {"trait_type": "generation", "value": "',
                        StringLib.uintToString(generation),
                        '"}, {"trait_type": "month", "value": "',
                        StringLib.uintToString(month),
                        '"}, {"trait_type": "day", "value": "',
                        StringLib.uintToString(day),
                        '"}]}'
                    )
                )
            )
        );

        _rawSVG = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return _rawSVG;
    }

    ///*********constants */
    string constant golden0 = "e3d8ab";
    string constant golden1 = "ab6e13";
    string constant golden2 = "b49d5d";
    string constant silver0 = "c1c1c1";
    string constant silver1 = "757575";
    string constant silver2 = "989898";

    function soGenSVG(
        uint16[] memory cusps,
        uint16[] memory planets,
        uint32 generation,
        uint16 month,
        uint16 day
    ) public view returns (string memory result) {
        require(cusps.length == 12, "wrong csups");
        require(planets.length == 11, "wrong planets");
        //s0-color-s1-color-s2-color-s3-circles-s4
        bool isGen0 = generation == 0;
        FireGenerator.ElementType elementType = fireGenerator.judgeElementTypeByPlanetDegree(planets[0]);
        if (isGen0) {
            //TODO(ironman_ch): move these code to FireGenerator
            string memory part2 = FireGenerator2.svgPart2(isGen0, elementType);
            part2 = fireGenerator.replaceThemeColor(isGen0, elementType, month, day, part2);
            result = concat(FireGenerator2.svgPart0(), golden0);
            result = concat(result, FireGenerator2.svgPart1());
            result = concat(result, golden1);
            result = concat(result, part2);
            // result = concat(result, golden2); will concat in the firegenerato
        } else {
            result = concat(FireGenerator2.svgPart0(), silver0);
            result = concat(result, FireGenerator2.svgPart1());
            result = concat(result, silver1);
            result = concat(result, FireGenerator2.svgPart2(isGen0, elementType));
            // result = concat(result, silver2); will concat in the firegenerator
        }
        //TODO(ironman_ch): move these code to FireGenerator
        string memory part3 = FireGenerator2.svgPart3(isGen0, elementType);
        part3 = fireGenerator.replaceThemeColor(isGen0, elementType, month, day, part3);
        result = concat(result, part3);

        string memory date = concat(
            concat(uintToString(month), "."),
            uintToString(day)
        );
        string memory centralText = string(abi.encodePacked(
            '<g filter="drop-shadow(0 1px 1px #000)">',
            text(
                "600",
                "600",
                concat(
                    concat(unicode"「Gen ", uintToString(generation)),
                    unicode"」"
                ),
                "2rem"
            ),
            text(
                "600",
                "650",
                concat(concat(unicode"✦ ", date), unicode" ✦"),
                "1.5rem"
            ),
            '</g>'
        ));
        string memory cuspsInSVG = genCuspsAsLines(cusps);
        (string memory planetsInSVG, string memory relationLines) = genPlanetsAsText(planets);
        FireGenerator.GenAndElement memory params = FireGenerator.GenAndElement({
            isGen0: isGen0, elementType: elementType, cuspsBody: cuspsInSVG, planetsBody: planetsInSVG, planets: planets
        });
        FireGenerator.ParamsPart2 memory paramsPart2 = FireGenerator.ParamsPart2({
            relationLines: relationLines,
            centralText: centralText,
            month: month,
            day: day
        });

        result = concat(result, fireGenerator.completeChartBody(params, paramsPart2));

        
        
        result = concat(result, "</svg>");
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(string memory self, string memory other)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(self, other));
    }

    function uintToString(uint256 value) private pure returns (string memory) {
        return string(uintToBytes(value));
    }

    function uintToBytes(uint256 value) private pure returns (bytes memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return buffer;
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.  (eee.aaa).tostring
     */
    function intToFixedNx4String(int256 value)
        public
        pure
        returns (string memory)
    {
        string memory sign = "";
        if (value < 0) {
            sign = "-";
            value = -value;
        }
        bytes memory buffer = uintToBytes(uint256(value));
        string memory interger = "";
        string memory decimal = "";
        if (buffer.length <= 4) {
            interger = "0.";
            decimal = string(buffer);
            while (bytes(decimal).length < 4) {
                decimal = concat("0", decimal);
            }
            interger = concat(sign, interger);
            return concat(interger, decimal);
        } else {
            bytes memory tmp = new bytes(1);
            for (uint256 i = 0; i < buffer.length - 4; i++) {
                tmp[0] = buffer[i];
                interger = concat(interger, string(tmp));
            }
            interger = concat(interger, ".");
            for (uint256 i = buffer.length - 4; i < buffer.length; i++) {
                tmp[0] = buffer[i];
                decimal = concat(decimal, string(tmp));
            }
            interger = concat(sign, interger);
            return concat(interger, decimal);
        }
    }

    // to 64.64 fixed point number
    function to64x64(int128 x) public pure returns (int128) {
        unchecked {
            return XpMath.divi(x, PRECISION);
        }
    }

    // from 64.64 fixed point number to uint
    function toInt(int128 x) public pure returns (int256) {
        return XpMath.muli(x, PRECISION);
    }

    function genLineCoordinates(
        int128 alpha,
        int128 r0,
        int128 r1
    ) public pure returns (int256[4] memory coordinates) {
        int128 cx = 600 << 64;
        r0 = r0 << 64;
        r1 = r1 << 64;
        return [
            toInt(XpMath.add(cx, XpMath.mul(r0, XpMath.cos(alpha)))),
            toInt(XpMath.sub(cx, XpMath.mul(r0, XpMath.sin(alpha)))),
            toInt(XpMath.add(cx, XpMath.mul(r1, XpMath.cos(alpha)))),
            toInt(XpMath.sub(cx, XpMath.mul(r1, XpMath.sin(alpha))))
        ];
    }

    function genRelationLineCoord(
        int128 r,
        int128 alpha,
        int128 beta
    ) public pure returns (int256[4] memory coordinates) {
        r = r << 64;
        int128 cx = 600 << 64; //center
        return [
            toInt(XpMath.add(cx, XpMath.mul(r, XpMath.cos(alpha)))),
            toInt(XpMath.sub(cx, XpMath.mul(r, XpMath.sin(alpha)))),
            toInt(XpMath.add(cx, XpMath.mul(r, XpMath.cos(beta)))),
            toInt(XpMath.sub(cx, XpMath.mul(r, XpMath.sin(beta))))
        ];
    }

    function genCuspsAsLines(uint16[] memory cusps)
        private
        pure
        returns (string memory res)
    {
        int128[] memory cusps64x64 = new int128[](12);

        for (uint8 i = 0; i < cusps.length; i++) {
            cusps64x64[i] = to64x64(int32(uint32(cusps[i])));
        }
        for (uint32 i = 0; i < cusps.length; i += 1) {
            int256[4] memory xy = genLineCoordinates(cusps64x64[i], 230, 355);
            res = concat(
                res,
                line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Default)
            ); //20000 means 2.0000
        }
    }

    function fixOverlap(uint16[] memory _planets)
        public
        pure
        returns (uint16[] memory)
    {
        for (uint8 i = 1; i < _planets.length; i++) {
            for (uint8 j = 0; j <i ; j++) {
                // detect and move it
                int128 diff = XpMath.abs(
                    int128(uint128(_planets[i])) - int128(uint128(_planets[j]))
                );
                if (diff <= OVERLAP_DETECT) {
                    uint256 tmp = _planets[j] + SPACE_RAD;
                    _planets[i] = uint16(tmp % 65536);
                }
            }
        }
        return _planets;
    }
    function genPlanetsAsText(uint16[] memory _planets)
        private
        pure
        returns (string memory res, string memory relationLines)
    {
        string[11] memory PLANETS_TEXT = [
            unicode"☉", //0
            unicode"☽", //1
            unicode"☿", //2
            unicode"♀", //3
            unicode"♂", //4
            unicode"♃", //5
            unicode"♄", //6
            unicode"♅", //7
            unicode"♆", //8
            unicode"♇", //9
            "ASC"
        ];
        //sort for detect overlap, small to big
        uint16[] memory planets = new uint16[](_planets.length);
        for(uint8 i = 0; i < _planets.length; i++) {
            planets[i] = _planets[i];
        }
        for (uint256 i = 0; i < planets.length; i++) {
            for (uint256 j = i + 1; j < planets.length; j++) {
                if (planets[i] > planets[j]) {
                    uint16 temp = planets[i];
                    planets[i] = planets[j];
                    planets[j] = temp;
                    string memory tmpStr = PLANETS_TEXT[i];
                    PLANETS_TEXT[i] = PLANETS_TEXT[j];
                    PLANETS_TEXT[j] = tmpStr;
                }
            }
        }
        //draw Realtionship lines
        relationLines = drawPlanetRelationLines(planets);
        //copy to a int128 array
        int128[] memory realPlanets64x64 = new int128[](11);
        for (uint8 i = 0; i < planets.length; i++) {
            //never overflow, planets is a uint16 array
            realPlanets64x64[i] = to64x64(int32(uint32(planets[i])));
        }
        //fix overlap
        planets=fixOverlap(planets);
        int128[] memory planets64x64 = new int128[](11);
        for (uint8 i = 0; i < planets.length; i++) {
            //to64x64
            planets64x64[i] = to64x64(int32(uint32(planets[i])));
        }
        //draw planets
        for (uint32 i = 0; i < PLANETS_TEXT.length; i++) {
            int256[4] memory xy = genLineCoordinates(
                planets64x64[i],
                0,
                345 - 30
            );

            string memory fontSize = i == PLANETS_TEXT.length - 1 ? "25" : "30";
            res = concat(
                res,
                text(
                    intToFixedNx4String(xy[2]),
                    intToFixedNx4String(xy[3]),
                    PLANETS_TEXT[i],
                    fontSize
                )
            );
            int256[4] memory xy1 = genLineCoordinates(
                realPlanets64x64[i],
                0,
                355 //target R
            );
            xy = genLineCoordinates(planets64x64[i], 0, 345 - 30);
            res = concat(res, dot(xy1[2], xy1[3]));
        }
    }

    function drawPlanetRelationLines(uint16[] memory planets)
        public
        pure
        returns (string memory res)
    {
        for (uint8 i = 0; i < planets.length; i++) {
            for (uint8 j = i + 1; j < planets.length; j++) {
                res = concat(
                    res,
                    drawPlanetRelationLine(planets[i], planets[j])
                );
            }
        }
    }

    // Require A <= B
    function drawPlanetRelationLine(uint16 planetA, uint16 planetB)
        public
        pure
        returns (string memory res)
    {
        require(planetA <= planetB, "PRL");
        int128 radius = 228;
        uint16 diff = planetB - planetA;
        int256[4] memory xy;
        res = "";
        xy = genRelationLineCoord(
            radius,
            to64x64(int32(uint32(planetA))),
            to64x64(int32(uint32(planetB)))
        );
        if (DOWN60 <= diff && diff <= UP60) {
            //60
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Yellow);
        } else if (DOWN90 <= diff && diff <= UP90) {
            //90
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Red);
        } else if (DOWN120 <= diff && diff <= UP120) {
            //120
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Green);
        } else if (DOWN180 <= diff && diff <= UP180) {
            //180
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Blue);
        }
    }

    function text(
        string memory x,
        string memory y,
        string memory content,
        string memory fontSize
    ) private pure returns (string memory res) {
        res = '<text text-anchor="middle" ';
        res = setAttribute(res, "x", x);
        res = setAttribute(res, "y", y);
        res = setAttribute(res, "font-size", fontSize);
        res = concat(res, ">");
        res = concat(res, content);
        res = concat(res, "</text>");
    }

    function dot(int256 x, int256 y) private pure returns (string memory res) {
        res = "<circle";
        res = setAttribute(res, "cx", intToFixedNx4String(x));
        res = setAttribute(res, "cy", intToFixedNx4String(y));
        res = setAttribute(res, "r", "3");
        res = setAttribute(res, "fill", "#000");
        res = concat(res, "/>");
    }

    function line(
        int256 x1,
        int256 y1,
        int256 x2,
        int256 y2,
        int256 width,
        LineColor color
    ) private pure returns (string memory) {
        return
            lineForString(
                intToFixedNx4String(x1),
                intToFixedNx4String(y1),
                intToFixedNx4String(x2),
                intToFixedNx4String(y2),
                intToFixedNx4String(width),
                color
            );
    }

    function lineForString(
        string memory x1,
        string memory y1,
        string memory x2,
        string memory y2,
        string memory width,
        LineColor color
    ) private pure returns (string memory) {
        string memory l = "<line ";
        l = setAttribute(l, "x1", x1);
        l = setAttribute(l, "y1", y1);
        l = setAttribute(l, "x2", x2);
        l = setAttribute(l, "y2", y2);
        l = setAttribute(l, "stroke-width", width);
        if (color != LineColor.Default) {
            if (color == LineColor.Red) {
                l = setAttribute(l, "stroke", "#b41718"); //Red
            } else if (color == LineColor.Green) {
                l = setAttribute(l, "stroke", "#3069ce"); //Green
            } else if (color == LineColor.Blue) {
                l = setAttribute(l, "stroke", "#3764B1"); //Blue
            } else if (color == LineColor.Yellow) {
                l = setAttribute(l, "stroke", "#E3CD6F"); //Yellow
            }
        }
        return concat(l, "/>");
    }

    function setAttribute(
        string memory origin,
        string memory key,
        string memory value
    ) private pure returns (string memory res) {
        res = concat(origin, " ");
        res = concat(res, key);
        res = concat(res, '="');
        res = concat(res, value);
        res = concat(res, '"');
    }
}

// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DateUtils.sol";
// import "hardhat/console.sol";

struct AstroChartArgs {
    uint16[] monthAndDay;
    string remaining;
    bool exists;
    uint32 generation;
}

struct BreedConfig {
    uint32 alreadyBredCount;
    uint256 breedPrice;
    uint256 bredFromRootTokenId;
}

library AstroChartLib {
    // the limit for initial mint
    uint256 private constant INITIAL_MINT_LIMIT = 366;
    uint256 private constant SALES_START_PRICE = 1000 ether;
    uint256 private constant PRICE_DROP_DURATION = 600; // 10 mins
    uint256 private constant PRICE_DROP_PERCENT = 10;
    uint256 private constant PRICE_DROP_FLOOR = 0.1 ether;

    struct LibStorage {
        bool noDateLimitPrimeMint;
        // already minted for initial minting
        uint256 initalMintCount;
        // salesStartTime, offset from day's 0 clock, unit: seconds
        uint256 salesStartTime;
        // salesEndTime, offset from day's 0 clock, unit: seconds
        uint256 salesEndTime;
        // initial deposit
        uint256 initialDeposit;
        // initial mint's conflict detector
        mapping(bytes32 => uint256) mintedDate2PrimeTokenId;
        // record tokenId to origin data
        mapping(uint256 => AstroChartArgs) tokenIdToAstroData;
        // record tokenId to breed next generation's price and alreadBredCount
        mapping(uint256 => BreedConfig) tokenIdToBreedConfig;
        // record owner to pending withdraws
        mapping(address => uint256) pendingWithdraws;
        uint256 nextTokenId;
        // charge the oracle gas fee for oracle operator to submit transaction
        uint256 oracleGasFee;
    }

    // return a struct storage pointer for accessing the state variables
    function libStorage() internal pure returns (LibStorage storage ds) {
        bytes32 position = keccak256("AstroChartLib.storage");
        assembly {
            ds.slot := position
        }
    }

    function _initNextTokenId(uint256 initValue) public {
        libStorage().nextTokenId = initValue;
    }

    /**
     * @dev calculates the next token ID based on totalSupply
     * @return uint256 for the next token ID
     */
    function _nextTokenId() private returns (uint256) {
        uint256 res = libStorage().nextTokenId;
        libStorage().nextTokenId += 1;
        return res;
    }

    function getOracleGasFee() public view returns (uint256) {
        return libStorage().oracleGasFee;
    }

    function setOracleGasFee(uint256 _fee) public {
        libStorage().oracleGasFee = _fee;
    }

    /**
    set the sales startTime and endTime, only can be done by owner
     */
    function setSalesTimes(uint256 _salesStartTime, uint256 _salesEndTime) public {
        libStorage().salesStartTime = _salesStartTime;
        libStorage().salesEndTime = _salesEndTime;
    }

    function getSalesTimes() public view returns (uint256, uint256) {
        return (libStorage().salesStartTime, libStorage().salesEndTime);
    }

    function initialDeposit() public view returns (uint256) {
        return libStorage().initialDeposit;
    }

    function initialMintCount() public view returns (uint256) {
        return libStorage().initalMintCount;
    }

    function beginNoDateLimitPrimeMint() public {
        libStorage().noDateLimitPrimeMint = true;
    }

    function isNoDateLimitPrimeMintBegan() public view returns (bool) {
        return libStorage().noDateLimitPrimeMint;
    }

    function initialMintDry(uint16[] calldata monthAndDay, string calldata remaining) public returns (uint256 tokenId) {
        //checks
        require(libStorage().initalMintCount < INITIAL_MINT_LIMIT, "IMLA");

        uint256 price = getPrice();
        require(msg.value >= getPrice() + libStorage().oracleGasFee, "IMSPWI+O");

        require(price != 0, "SNS");

        uint16 month = monthAndDay[0];
        uint16 day = monthAndDay[1];
        require(libStorage().mintedDate2PrimeTokenId[dateToBytes32(month, day)] == 0, "IMDAE");

        if (!isNoDateLimitPrimeMintBegan()) {
            require(DateUtils.getDayFromTimestamp(block.timestamp) == day, "DTNT");
        }

        _checkForDateAndCity(monthAndDay);

        //effects
        AstroChartArgs memory args = AstroChartArgs({
            monthAndDay: monthAndDay,
            remaining: remaining,
            exists: true,
            generation: 0
        });

        tokenId = _nextTokenId();
        libStorage().tokenIdToAstroData[tokenId] = args;
        libStorage().initalMintCount++;
        libStorage().initialDeposit += msg.value;
        libStorage().mintedDate2PrimeTokenId[dateToBytes32(month, day)] = tokenId;
    }

    function regenerateDry(
        uint256 tokenId,
        address ownerOfToken,
        uint16[] calldata _monthAndDay,
        string calldata remaining
    ) public {
        //require
        require(ownerOfToken == msg.sender, "TNOBS");
        require(msg.value >= libStorage().oracleGasFee, "RSPWO");
        AstroChartArgs memory originArgs = libStorage().tokenIdToAstroData[tokenId];
        require(_monthAndDay[0] == originArgs.monthAndDay[0] && _monthAndDay[1] == originArgs.monthAndDay[1], "MDSETO");
        _checkForDateAndCity(_monthAndDay);

        //effect
        AstroChartArgs memory args = AstroChartArgs({
            monthAndDay: _monthAndDay,
            remaining: remaining,
            exists: true,
            generation: 0
        });
        libStorage().tokenIdToAstroData[tokenId] = args;
        libStorage().initialDeposit += msg.value;
    }

    function getTokenIdByMonthAndDay(uint16 month, uint16 day) public view returns (uint256) {
        return libStorage().mintedDate2PrimeTokenId[dateToBytes32(month, day)];
    }

    function dateToBytes32(uint16 month, uint16 day) private pure returns (bytes32) {
        bytes memory encoded = abi.encodePacked(month, day);
        return bytesToBytes32(encoded);
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32 out) {
        for (uint8 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
    }

    function getPrice() public view returns (uint256) {
        if (libStorage().salesStartTime == 0) {
            return 0;
        }

        uint256 currentTimeOffset = DateUtils.getUTCSecondsOffsetInDay(block.timestamp);
        uint256 startSalesTime = libStorage().salesStartTime;

        if (currentTimeOffset < startSalesTime) {
            return 0;
        }

        uint256[75] memory priceTable = [
            (uint256)(900.0 ether),
            810.0 ether,
            729.0 ether,
            656.1 ether,
            590.4 ether,
            531.4 ether,
            478.2 ether,
            430.4 ether,
            387.4 ether,
            348.6 ether,
            313.8 ether,
            282.4 ether,
            254.1 ether,
            228.7 ether,
            205.8 ether,
            185.3 ether,
            166.7 ether,
            150.0 ether,
            135.0 ether,
            121.5 ether,
            109.4 ether,
            98.4 ether,
            88.6 ether,
            79.7 ether,
            71.7 ether,
            64.6 ether,
            58.1 ether,
            52.3 ether,
            47.1 ether,
            42.3 ether,
            38.1 ether,
            34.3 ether,
            30.9 ether,
            27.8 ether,
            25.0 ether,
            22.5 ether,
            20.2 ether,
            18.2 ether,
            16.4 ether,
            14.7 ether,
            13.3 ether,
            11.9 ether,
            10.7 ether,
            9.6 ether,
            8.7 ether,
            7.8 ether,
            7.0 ether,
            6.3 ether,
            5.7 ether,
            5.1 ether,
            4.6 ether,
            4.1 ether,
            3.7 ether,
            3.3 ether,
            3.0 ether,
            2.7 ether,
            2.4 ether,
            2.2 ether,
            1.9 ether,
            1.7 ether,
            1.6 ether,
            1.4 ether,
            1.3 ether,
            1.1 ether,
            1.0 ether,
            0.9 ether,
            0.8 ether,
            0.7 ether,
            0.6 ether,
            0.6 ether,
            0.5 ether,
            0.4 ether,
            0.3 ether,
            0.2 ether,
            0.1 ether
        ];

        // Public sales
        uint256 dropCount = (currentTimeOffset - startSalesTime) / PRICE_DROP_DURATION;

        return dropCount < priceTable.length ? priceTable[dropCount] : PRICE_DROP_FLOOR;
    }

    /**
    require monthAndDay.length == 2 and monthAndDay is valid or else throw "datetime not valid" as "DTNV"
    */
    function _checkForDateAndCity(uint16[] calldata monthAndDay) private view {
        require(monthAndDay.length == 2, "DTNV");
        uint16 month = monthAndDay[0];
        uint16 day = monthAndDay[1];
        require(DateUtils.isDateValid(2012, month, day), "DTNV");
    }

    function setBreedPrice(uint256 tokenId, uint256 breedPrice) public {
        //effects
        libStorage().tokenIdToBreedConfig[tokenId].breedPrice = breedPrice;
    }

    function getBreedPrice(uint256 tokenId) public view returns (uint256) {
        BreedConfig storage breedConfig = libStorage().tokenIdToBreedConfig[tokenId];
        AstroChartArgs memory args = getAstroArgsOf(tokenId);
        return getBreedPriceInner(breedConfig, args);
    }

    function getBreedPriceInner(BreedConfig storage breedConfig, AstroChartArgs memory astroChartArgs)
        internal
        view
        returns (uint256)
    {
        uint256 userBreedPrice = breedConfig.breedPrice;
        return userBreedPrice == 0 ? suggestBreedPrice(astroChartArgs) : userBreedPrice;
    }

    function suggestBreedPrice(AstroChartArgs memory astroChartArgs) internal pure returns (uint256) {
        uint256 generation = astroChartArgs.generation;
        return 1 ether / (2**generation);
    }

    function withdrawBreedFee() public {
        //checks
        require(libStorage().pendingWithdraws[msg.sender] > 0, "PWMLTZ");

        //effects
        libStorage().pendingWithdraws[msg.sender] = 0;

        //interactions
        payable(msg.sender).transfer(libStorage().pendingWithdraws[msg.sender]);
    }

    function breedFromDry(
        uint256 fromTokenId,
        uint16[] calldata monthAndDay,
        string calldata remaining,
        address ownerOfFromToken,
        AstroChartArgs memory astroDataOfParentToken
    ) public returns (uint256 bredTokenId) {
        //checks
        BreedConfig storage breedConfig = libStorage().tokenIdToBreedConfig[fromTokenId];
        require(
            msg.value >= getBreedPriceInner(breedConfig, astroDataOfParentToken) + libStorage().oracleGasFee,
            "LTBP+O"
        );
        _checkForDateAndCity(monthAndDay);
        require(monthAndDay[0] == astroDataOfParentToken.monthAndDay[0], "MNE");
        require(monthAndDay[1] == astroDataOfParentToken.monthAndDay[1], "DNE");

        require(breedConfig.alreadyBredCount < breedingLimitationOf(astroDataOfParentToken.generation), "BGBL");

        //effects
        AstroChartArgs memory args = AstroChartArgs({
            monthAndDay: monthAndDay,
            remaining: remaining,
            exists: true,
            generation: astroDataOfParentToken.generation + 1
        });

        //set bredToken to astro data
        bredTokenId = _nextTokenId();
        libStorage().tokenIdToAstroData[bredTokenId] = args;

        //set breedConfig.bredFromRootTokenId
        libStorage().tokenIdToBreedConfig[bredTokenId].bredFromRootTokenId = breedConfig.bredFromRootTokenId == 0
            ? fromTokenId
            : breedConfig.bredFromRootTokenId;

        //update pending withdraw of from token's owner
        libStorage().pendingWithdraws[ownerOfFromToken] += breedConfig.breedPrice;

        //add oracleGadFee to initialDeposit
        libStorage().initialDeposit += msg.value - breedConfig.breedPrice;
        // update alreadyBredCount of fromToken
        breedConfig.alreadyBredCount += 1;
    }

    function breedingLimitationOf(uint32 generation) public pure returns (uint32 res) {
        if (generation == 0) {
            return 2**32 - 1;
        }

        if (generation > 10) {
            return 0;
        }

        uint32 revisedGen = 10 - generation;
        res = uint32(1) << revisedGen;
    }

    function getAstroArgsOf(uint256 tokenId) public view returns (AstroChartArgs memory) {
        return libStorage().tokenIdToAstroData[tokenId];
    }

    function getBreedConfigOf(uint256 tokenId) public view returns (BreedConfig memory) {
        return libStorage().tokenIdToBreedConfig[tokenId];
    }

    function getPendingWithdraw() public view returns (uint256) {
        return libStorage().pendingWithdraws[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library StringLib {
    
    function intToString(int128 value) internal pure returns (string memory) {
        bool isNegative = false;
        uint256 uintValue = 0;
        if (value < 0) {
            isNegative = true;
            uintValue = uint256(int256(value * -1));
        } else {
            isNegative = false;
            uintValue = uint256(int256(value));
        }
        string memory uString = uintToString(uintValue);
        return isNegative ? concat("-", uString) : uString;
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function stringToUint(bytes memory b) internal pure returns (uint256) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            uint8 bInU8 = uint8(b[i]);
            if (bInU8 >= 48 /**0 */ && bInU8 <= 57 /**9 */) {
                result = result * 10 + (bInU8 - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
}

    function concat(string memory self, string memory other) internal pure returns (string memory) {
        return string(abi.encodePacked(self, other));
    }

    function replace(string memory _str, string memory _pattern, string memory _replacement) internal pure returns (string memory res) {
        
        bytes memory _strBytes = bytes(_str);
        bytes memory pattern = bytes(_pattern);
        bytes memory _replacementBytes = bytes(_replacement);
        require(pattern.length > 0, "pattern's length should L.T. 0");
        uint256 lastHitEndIndexPlus1 = 0;
        for (uint256 i = 0; i < _strBytes.length; i++) {
            //judge if hit
            bool hit = true;
            for (uint256 j = 0; j < pattern.length; j++) {
                if (_strBytes[i + j] != pattern[j]) {
                    hit = false;
                    break;
                }
            }
            
            if (hit) {
                //concat bytes from lastHitEndIndex to i
                res = string(abi.encodePacked(
                    res, substring(_strBytes, lastHitEndIndexPlus1, i), _replacementBytes
                ));
                //update lastHitEndIndex
                lastHitEndIndexPlus1 = i + pattern.length;
                //move i to the tail of the pattern
                i += pattern.length - 1;
            }
        }

        //concat the last part after replace
        res = string(abi.encodePacked(
            res, substring(_strBytes, lastHitEndIndexPlus1, _strBytes.length)
        ));
    }

    function find(bytes memory str, bytes memory pattern) internal pure returns (uint256 index1, uint256 index2, bool exist) {
       uint times = 0;
       for (uint256 i = 0; i < str.length; i++) {
            //judge if hit
            bool hit = true;
            for (uint256 j = 0; j < pattern.length; j++) {
                if (str[i + j] != pattern[j]) {
                    hit = false;
                    break;
                }
            } 
            if (hit == true) {
                if (times == 0) {
                    index1 = i;
                } else if (times == 1) {
                    index2 = i;
                }
                times ++;
                exist = true;
            }
       }
    }

    function substring(bytes memory strBytes, uint startIndex, uint endIndex) internal pure returns (bytes memory) {
        if (endIndex <= startIndex) {
            return bytes("");
        }

        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return result;
    }

    /**
    hsl format is: hsl(60,100%,95%)
     */
    function parseHSL(string memory hsl) internal pure returns (uint256 h, uint256 s, uint256 l) {
        (uint256 posOfFirstComma, uint256 posOfSecondComma, bool _success) = find(bytes(hsl), bytes(","));
        bytes memory hslInBytes = bytes(hsl);
        h = stringToUint(substring(hslInBytes, 4/**hsl(*/, posOfFirstComma));
        s = stringToUint(substring(hslInBytes, posOfFirstComma/**hsl(*/, posOfSecondComma - 1 /**remove %*/));
        l = stringToUint(substring(hslInBytes, posOfSecondComma/**hsl(*/, hslInBytes.length - 2 /**remove %)*/));
    }

    function parseCompressedHSL(bytes memory compressedHSLArray, uint256 index) internal pure returns (uint16, uint16, uint16) {
        uint256 length = compressedHSLArray.length;
        require(length % 8 == 0, "compressedHSLArray.length must be multiplier of 4");
        require(length / 8 > index, "compressedHSLArray.length must be L.T. index");
        
        index = index * 8;
        //for H(0-360)
        uint8 hHightestBit = fromHex(compressedHSLArray[index], compressedHSLArray[index + 1]);
        uint8 hLowestByte = fromHex(compressedHSLArray[index+2], compressedHSLArray[index + 3]);
        uint16 h = hHightestBit == 0 ? hLowestByte : uint16(256) + hLowestByte;
        //for S
        uint16 sLowest7Bits = fromHex(compressedHSLArray[index+4], compressedHSLArray[index + 5]);
        //for L
        uint16 lLowest7Bits = fromHex(compressedHSLArray[index+6], compressedHSLArray[index + 7]);       

        return (h, sLowest7Bits, lLowest7Bits);
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(bytes1 high, bytes1 low) public pure returns (uint8) {
        return fromHexChar(uint8(high)) * 16 + fromHexChar(uint8(low));
    }

    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        } else if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        } else if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE FILE
pragma solidity ^0.8.4;
// This ABDKMath64x64 Library has a differnet license in /libraies/LICENSE.md
import "./libraries/ABDKMath64x64.sol";

library XpMath {
    //64 bit decimal number pricision is 0.00000000000000000005421
    //pi=       3.1415926535897932384626433832795 decimal= 2611928677177517772=  243f6f4b15d266cc
    //halfpi=   1.5707963267948966192313216916398 decimal= 10529354856943306017= 921fc8749a23c521
    //quarterpi=0.7853981633974483096156608458198 decimal= 14488067946826200140= c90ff5095c4c744c
    //twopi=    6.2831853071795864769252867665590 decimal= 5223857354355035545=  487ede962ba4cd99
    int128 private constant PI =        0x0000000000000003243F6F4B15D266CC;
    int128 private constant HALFPI =    0x0000000000000001921fc8749a23c521;
    int128 private constant QUARTERPI = 0x0000000000000000c90ff5095c4c744c;
    int128 private constant TWOPI =     0x0000000000000006487EDE962BA4CD99;

    //------------------FUNCTIONS FROM ABDKMath64x64----------------------------//
    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        return ABDKMath64x64.fromInt(x);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return ABDKMath64x64.toInt(x);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        return ABDKMath64x64.fromUInt(x);
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        return ABDKMath64x64.toUInt(x);
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        return ABDKMath64x64.from128x128(x);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return ABDKMath64x64.to128x128(x);
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.add(x, y);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.sub(x, y);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.mul(x, y);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        return ABDKMath64x64.muli(x, y);
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        return ABDKMath64x64.mulu(x, y);
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.div(x, y);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        return ABDKMath64x64.divi(x, y);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        return ABDKMath64x64.divu(x, y);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.neg(x);
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.abs(x);
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.inv(x);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.avg(x, y);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.gavg(x, y);
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        return ABDKMath64x64.pow(x, y);
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.sqrt(x);
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.log_2(x);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.ln(x);
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.exp_2(x);
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.exp(x);
    }

    //------------------FUNCTIONS FROM ABDKMath64x64 END-------------------------//

    /**
     * Calculate sine of x.  Revert on overflow.
     * use y = 0.987862x - 0.155271x^3 + 0.00564312x^5
     * a=0.987862 = 18222874008485519276= fce4a75c9e7a5fac
     * b=0.155271 = 2864250138350857775 = 27bfdc534c442e2f
     * c=0.00564312=104097399003873824  = 0171d40869ab0220
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sin(int128 x) internal pure returns (int128) {
        //this approximation only for x in range [-pi/2,pi/2]
        while (x > PI) {
            x = sub(x, TWOPI);
        }
        while (x < neg(PI)) {
            x = add(x, TWOPI);
        }
        if(abs(sub(x,HALFPI))<divi(1,100)){
            return fromUInt(1);
        }
        if(abs(sub(x,neg(HALFPI)))<divi(1,100)){
            return neg(fromUInt(1));
        }
        if(abs(sub(x,PI))<divi(1,50)||abs(sub(x,neg(PI)))<divi(1,50)){
            return fromUInt(0);
        }
        if(x<0){
            return neg(sin(neg(x)));
        }
        if(x>=HALFPI){
            return (sin(sub(PI,x)));
        }
        // next line use tylar approximation
        // sin(x) =x - x^3/6 + x^5/120 - x^7/5040 + x^9/362880 - x^11/39916800
        int128 tmp=sub(x,div(pow(x,3),fromUInt(6)));
        tmp=add(tmp,div(pow(x,5),fromUInt(120)));
        tmp=sub(tmp,div(pow(x,7),fromUInt(5040)));
        //tmp=add(tmp,div(pow(x,9),fromUInt(362880)));
        //tmp=sub(tmp,divi(pow(x,11),39916800));
        return tmp;
    }

    function cos(int128 x) internal pure returns (int128) {
        return sin(add(x, HALFPI));
    }
    

}

// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
pragma solidity ^0.8.4;

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./StringLib.sol";
import "./DateUtils.sol";

contract FireGenerator {

    string constant GROUP_START = "<g>";
    string constant GROUP_END = "</g>";
    string constant EMPTY = "";

    //<body>
    //  <signsAndCuspsAndPlanetRelations>
    //     <signLines>
    //     </signLines>
    //     <signTexts>
    //     </signTexts>
    //     <cuspsAndPlanetRelations>
    //     </cuspsAndPlanetRelations>
    //  </signsAndCuspsAndPlanetRelations>
    //  <fire>
    //  </fire>
    //  <circles>
    //  </circles>
    //  <planets> 
    //  </planets>
    //  <centralTexts>
    //  </centralTexts>
    //</body>

    //sign lines
    string constant signLines = 
    '<line x1="942.9036" y1="691.8807" x2="996.0295" y2="706.1158" stroke-width="1"/>'
    '<line x1="942.9036" y1="508.1192" x2="996.0295" y2="493.8841" stroke-width="1"/>'
    '<line x1="851.0229" y1="348.9770" x2="889.9137" y2="310.0862" stroke-width="1"/>'
    '<line x1="691.8807" y1="257.0963" x2="706.1158" y2="203.9704" stroke-width="1"/>'
    '<line x1="508.1192" y1="257.0963" x2="493.8841" y2="203.9704" stroke-width="1"/>'
    '<line x1="348.9770" y1="348.9770" x2="310.0862" y2="310.0862" stroke-width="1"/>'
    '<line x1="257.0963" y1="508.1192" x2="203.9704" y2="493.8841" stroke-width="1"/>'
    '<line x1="257.0963" y1="691.8807" x2="203.9704" y2="706.1158" stroke-width="1"/>'
    '<line x1="348.9770" y1="851.0229" x2="310.0862" y2="889.9137" stroke-width="1"/>'
    '<line x1="691.8807" y1="942.9036" x2="706.1158" y2="996.0295" stroke-width="1"/>'
    '<line x1="851.0229" y1="851.0229" x2="889.9137" y2="889.9137" stroke-width="1"/>'
    '<line x1="508.1192" y1="942.9036" x2="493.8841" y2="996.0295" stroke-width="1"/>';

    string constant signLines_tail = GROUP_END;

    //sign texts
    string constant signTexts = 
    '<text font-size="25" transform="translate(990, 635) rotate(-90)" fill="#ac303e" font-weight="bold" stroke="none">ARIES</text>'
    '<text font-size="25" transform="translate(895, 370) rotate(60)" fill="#e8cc5e" font-weight="bold" stroke="none">TAURUS</text>'
    '<text font-size="25" transform="translate(750, 255) rotate(30)" fill="#026d49" font-weight="bold" stroke="none">GEMINI</text>'
    '<text font-size="25" transform="translate(545, 230) rotate(0)" fill="#2478d2" font-weight="bold" stroke="none">CANCER</text>'
    '<text font-size="25" transform="translate(395, 290) rotate(-30)" fill="#ac303e" font-weight="bold" stroke="none">LEO</text>'
    '<text font-size="25" transform="translate(260, 445) rotate(-60)" fill="#e8cc5e" font-weight="bold" stroke="none">VIRGO</text>'
    '<text font-size="25" transform="translate(210, 565) rotate(90)" fill="#026d49" font-weight="bold" stroke="none">LIBRA</text>'
    '<text font-size="25" transform="translate(235, 750) rotate(60)" fill="#1d81d9" font-weight="bold" stroke="none">SCORPIO</text>'
    '<text font-size="25" transform="translate(335, 895) rotate(30)" fill="#ac303e" font-weight="bold" stroke="none">SAGITTARIUS</text>'
    '<text font-size="25" transform="translate(525, 990) rotate(0)" fill="#e8cc5e" font-weight="bold" stroke="none">CAPRICORN</text>'
    '<text font-size="25" transform="translate(740, 970) rotate(-30)" fill="#026d49" font-weight="bold" stroke="none">AQUARIUS</text>'
    '<text font-size="25" transform="translate(920, 830) rotate(-60)" fill="#2478d2" font-weight="bold" stroke="none">PISCES</text>';

    string constant signTexts_tail = GROUP_END;

    string constant cuspsAndPlanetRelations_tail = GROUP_END;

    string constant fireTemplate =             
    '<g filter="url(#goo)" clip-path="url(#centerCut)" stroke="none" transform="translate(240, 240) scale(0.6)">'
    '<circle class="f1" cy="753" cx="579" r="80" fill="#000000"/>'
    '<circle class="f2" cy="751" cx="622" r="80" fill="#000000"/>'
    '<circle class="f3" cy="770" cx="648" r="80" fill="#000000"/>'
    '<circle class="f4" cy="755" cx="614" r="80" fill="#000000"/>'
    '<circle class="f5" cy="744" cx="591" r="80" fill="#000000"/>'
    '<circle class="f6" cy="748" cx="572" r="80" fill="#000000"/>'
    '<circle class="f7" cy="746" cx="651" r="80" fill="#000000"/>'
    '<circle class="f8" cy="751" cx="604" r="80" fill="#000000"/>'
    '<circle class="f9" cy="734" cx="595" r="80" fill="#000000"/>'
    '<circle class="f10" cy="743" cx="569" r="80" fill="#000000"/>'
    '<circle class="f11" cy="758" cx="559" r="80" fill="#000000"/>'
    '<circle class="f12" cy="731" cx="632" r="80" fill="#000000"/>'
    '<circle class="f13" cy="737" cx="585" r="80" fill="#000000"/>'
    '<circle class="f14" cy="760" cx="616" r="80" fill="#000000"/>'
    '<circle class="f15" cy="752" cx="630" r="80" fill="#000000"/>'
    '<circle class="r1" cy="850" cx="600" r="90" fill="black"/>'
    '<circle class="r2" cy="850" cx="600" r="80" fill="black"/>'
    '<circle class="r3" cy="850" cx="600" r="80" fill="black"/>'
    '<circle class="r4" cy="850" cx="600" r="70" fill="black"/>'
    '<circle class="r5" cy="850" cx="600" r="60" fill="black"/>'
    '<circle class="r6" cy="850" cx="600" r="80" fill="black"/>'
    '<circle class="r7" cy="850" cx="600" r="70" fill="black"/>'
    '<circle class="r8" cy="850" cx="600" r="80" fill="black"/>'        
    '</g>';
    
    string constant circles_body = 
    "</circle>"
    '<circle cx="600" cy="600" r="430" stroke-width="1" fill="none"/>'
    '<circle cx="600" cy="600" r="420" stroke-width="1" fill="none"/>'
    '<circle cx="600" cy="600" r="410" stroke-width="1" fill="none"/>'
    '<circle cx="600" cy="600" r="400" stroke-width="10" fill="none" stroke-dasharray="1 62">'
    '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="60s" repeatCount="indefinite"/>'        "</circle>"
    '<circle cx="600" cy="600" r="355" stroke-width="2" fill="none"/>'
    '<circle cx="600" cy="600" r="230" stroke-width="2" fill="none"/>'
    '<circle cy="600" cx="600" r="85" fill="none" stroke-width="8" />'
    '<circle cy="600" cx="600" r="95" fill="none" stroke-width="2" />'
    ;

    string constant circles_tail = GROUP_END;

    //planets container head
    string constant planets_head = GROUP_START;

    //planets container tail
    string constant planets_tail = GROUP_END;
       
    string constant body_tail = GROUP_END; 

    

    function toHexString(uint24 number)
        private
        pure
        returns (string memory str)
    {
        bytes memory HEX = "0123456789ABCDEF";
        bytes memory wholeNumber = new bytes(6);
        for (uint256 i = 0; i < 6; i++) {
            uint256 c = (number >> (4 * i)) & 0xF;
            //c will be between 0 and 15
            wholeNumber[5 - i] = HEX[c];
        }
        str = string(wholeNumber);
    }

    function replace(string memory _str, string memory _replacement)
        private
        pure
        returns (string memory res)
    {
        bytes memory _strBytes = bytes(_str);
        bytes memory pattern = bytes("#0");
        bytes memory _replacementBytes = bytes(_replacement);
        require(_replacementBytes.length == 6, _replacement);
        for (uint256 i = 1; i < _strBytes.length; i++) {
            if (_strBytes[i] == pattern[1]&& _strBytes[i-1] == pattern[0]) {
                for (uint256 j = 0; j < 6; j++) {
                    _strBytes[i + j] = _replacementBytes[j];
                }
                i += 6;
            }
        }
        res = string(_strBytes);
    }

    function pickValueFromArrayByGenAndElement(string[5] memory arraySize5, bool isGen0, ElementType elementType) private pure returns (string memory) {
        require(arraySize5.length == 5, "arraySize5's length is not 5");
        if (isGen0) {
            if (elementType == ElementType.FIRE) {
                return arraySize5[1];
            } else if (elementType == ElementType.EARTH) {
                return arraySize5[2];
            } else if (elementType == ElementType.WATER) {
                return arraySize5[3];
            } else /**if (elementType == ElementType.WIND)*/ {
                return arraySize5[4];
            }
        } else /**if (!isGen0)*/ {
            return arraySize5[0];
        }
    }
    
    function drawSignsAndCuspsInOnGroup(bool isGen0, ElementType elementType, string memory cusps, string memory planetRelationLines) private pure returns (string memory) {
        string[5] memory signsAndCuspsAndPlanetRelations_head = [
            EMPTY,
            '<g filter="url(#light3)">',
            EMPTY,
            EMPTY,
            EMPTY
        ];

        string[5] memory signsAndCuspsAndPlanetRelations_tail = [EMPTY, GROUP_END, EMPTY, EMPTY, EMPTY];

        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(signsAndCuspsAndPlanetRelations_head, isGen0, elementType), 
            drawSignLinesInGroup(isGen0, elementType), 
            drawSignTextInGroup(isGen0, elementType), 
            drawCuspsAndPlanetRelationsInGroup(isGen0, elementType, cusps, planetRelationLines), 
            pickValueFromArrayByGenAndElement(signsAndCuspsAndPlanetRelations_tail, isGen0, elementType)
        ));
    }

    function drawSignLinesInGroup(bool isGen0, ElementType elementType) private pure returns (string memory) {
        string[5] memory signLines_head = [
            GROUP_START,
            '<g filter="url(#light2)">',
            GROUP_START,
            GROUP_START,
            GROUP_START
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(signLines_head, isGen0, elementType), 
            signLines,
            signLines_tail
        ));
    }

    function drawSignTextInGroup(bool isGen0, ElementType elementType) private pure returns (string memory) {
        string[5] memory signTexts_head = [
            GROUP_START,
            GROUP_START,
            GROUP_START,
            '<g><circle cx="600" cy="600" r="382" stroke-width="55" stroke="rgba(79,179,191,0.2)" fill="none" />',
            GROUP_START
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(signTexts_head, isGen0, elementType), 
            signTexts,
            signTexts_tail
        ));  
    }

    function drawCuspsAndPlanetRelationsInGroup(bool isGen0, ElementType elementType, string memory cusps, string memory planetRelationLines) private pure returns (string memory) {
        string[5] memory cuspsAndPlanetRelations_head = [
            GROUP_START,
            '<g filter="url(#light2)">',
            GROUP_START,
            GROUP_START,
            GROUP_START
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(cuspsAndPlanetRelations_head, isGen0, elementType), 
            cusps,
            planetRelationLines,
            cuspsAndPlanetRelations_tail
        ));
    }

    function completeChartBody(GenAndElement memory genAndElement, ParamsPart2 memory paramsPart2) public pure returns (string memory) {
        string[5] memory body_head = [
            '<g fill="url(#goldBody)" stroke="url(#goldBody)">',
            '<g stroke="#e37da2" fill="#e37da2">',
            '<g stroke="url(#gradient)" fill="url(#gradient)">',
            '<g stroke="#4fb3bf" fill="#4fb3bf">',
            '<g stroke="url(#gradient)" fill="url(#gradient)">'
        ];
        bool isGen0 = genAndElement.isGen0;
        ElementType elementType = genAndElement.elementType;
        string memory originBodyHead = pickValueFromArrayByGenAndElement(body_head, isGen0, elementType);
        string memory bodyHead = replaceThemeColor(isGen0, elementType, paramsPart2.month, paramsPart2.day, originBodyHead);
        return string(abi.encodePacked(
            bodyHead,
            drawSignsAndCuspsInOnGroup(isGen0, elementType, genAndElement.cuspsBody, paramsPart2.relationLines),
            drawFire(genAndElement.planets),
            drawCircles(isGen0, elementType),
            drawPlanets(genAndElement.planetsBody),
            drawCentralTexts(paramsPart2.centralText),
            body_tail
        ));
    }

    function drawFire(uint16[] memory planets) private pure returns (string memory) {
        //15deg=0.2618
        //FIRE red, EARTH yellow, WIND green, WATER blue
        uint16 red = 0;
        uint16 green = 0;
        uint16 blue = 0;
        uint8[6] memory index = [10, 0, 1, 2, 3, 4];
        for (uint256 i = 0; i < index.length; i++) {
            ElementType elementType = judgeElementTypeByPlanetDegree(planets[index[i]]);
            if (elementType == ElementType.FIRE) {
                red += 43;// 255/6
            } else if (elementType == ElementType.EARTH) {
                red += 43;
                green += 43;
            } else if (elementType == ElementType.WIND) {
                green += 43;
            } else /** if (elementType == ElementType.WATER)*/ {
                blue += 43;
            }
        }
        red = red > 255 ? 255 : red;
        green = green > 255 ? 255 : green;
        blue = blue > 255 ? 255 : blue;
        uint24 color = red * 65536 + green * 256 + blue;
        string memory hexColor = toHexString(color);
        return replace(fireTemplate, hexColor);
    }

    function drawCircles(bool isGen0, ElementType elementType) private pure returns (string memory) {
        string[5] memory circles_head = [
            GROUP_START,
            '<g filter="url(#light2)">',
            GROUP_START,
            GROUP_START,
            GROUP_START
        ];
        string[5] memory circle_first = [
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none" stroke-dasharray="260 20">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="30s" repeatCount="indefinite" />',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>'
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(circles_head, isGen0, elementType),
            pickValueFromArrayByGenAndElement(circle_first, isGen0, elementType),
            circles_body,
            circles_tail
        ));
    }

    function drawPlanets(string memory planets) private pure returns(string memory) {
        return string(abi.encodePacked(
            planets_head,
            planets,
            planets_tail
        ));
    }

    function drawCentralTexts(string memory centralText) private pure returns(string memory) {
        return centralText;
    }

    function genThemeColorReplacement(bool isGen0, ElementType elementType, uint16 month, uint16 day) private pure returns(string memory) {
        bytes memory birthdayColorInHex = bytes("003c645f0078095b00f0014500c003390140032c01460b280115640500413732004b421f004a252900592c4a00612a560083322b004b23290098641100493d5b00a66416007d1925004e3136009d382400c5484f00b8642300c9463600c3641c00de45130031364d003a643200336432004347320070262d00473c5100e5282a013c283900eb3b2001411c4901072a2301372251013a2138015c2f1d015b503d01544d4101524134015842340056042300361d2300cc474900ce274b00d51526000e321d00de361d002a645b00376450002d6035003664400048304f00560e5a0071104e003f183600422d1c006427270010534e0016575f015a4b5300024f3e015e632900005462000f524c01674c4f00064f5201665039002b4f5100004b3e0010533b00074d3301674d2f0139224a011d1c3301271b31011c4c1a012b152d00f41f4a013e2739010c1e2f012e252b01593130006f21540094245200af224b00be2e4c00c6553e0034474c015b4e6100155759015451500153404700da314400ca343d0046385c00831f38002b604100284f34001f2c57002c133800870a5c00f0013b006e085500ca09520000003601180227000c042000473f4000473d4b00883c29008b2843007128490084263e006c2b3a009d642200a9641d00b7642300b7642500b664200099641e00b76316009c610d00bc315300c9574600dd2932008e241e007b3d2c003d47580041453b003d4c3b00373f48003451190035304200353e28002932250000001c0043071c009b2544008d2029008c5e1400895c0e0099201600205b5000275c49002c643100183f2c000e1b260005225700024d4b011a1c4801031e3201244019003c425b004a3a51003a3849006f0d2c00333c1a00376453003864430034643100285f4300306432002f395e0016574e0025343401633a4a00081a24002b6049001f563d0026643000083727000a2b210160545601573d460156503f01604c4e0155632900c5425400d6313700c4641e00ce642400d5641c00c03f3600bd282d00bb313900bd631700c2641b001e0c6100d42e3a00dc243300d35e1b00dd3b180012565f01381f3a00db314800e61e3801294e1e00055550001c4740000d3337016531310165412c0161534e01503b450166352d015c2f260000001a00c2642400b4642000ca5e1900ca2e3100c5642a00c83a3500cc642100d9452600d2641e00d4621c00d05c1c00df2e1700db2c2c0125261a00f2154700b92f4300c64d3d00326436003964510039644b00235b3f00236431002164300010433d0023644c00296432002a3e3000282e3e0023401e00c5464e00c92c3800d52b3300d4352d012e43110077203d008f2c2600ad62140096641500a96411009d640c00b8293c00b6243900b9641500ef361400a0640a00ed2f1e00f0271a001b3332001a641c000a2c360078203e00cf1f50010a063100396458004c3356003d474e003b4e4100394336001f62470014583d000c563f00094d2f01534e3e012a24290012533d000d4c200012543900125533000e2a3f001b283a001e252b000e382e00173f1e00253131000c2a340012481e000a262000113d180015472b0030642e001c0e52003c054e00f0044600000031015f093b00a50324002d3b3800462b1f00130b3a00a2182b00b415230118022b00170c24015a182a011b1f5000172f3500251f2a00182d180012071e0147071d0025644b00226344001c5c36000e3c340021372400256454002f264e005a013f002c3416002c34130000575601473744000921390165253400ff043200471a4b00581549002c113700d2013100a008190015614e00205b580020422b001e1f2a0034101d0023214d00212a41000c451f002b102000330f1b00293d4b00313c4c0034402800252536001f4129000d5c530008584b000856460019642f0163223600125f57002a40520008213900254140015a0b29013e295001071e3c010b282b01042210012e1d28002d503400421140002b4d2e0029193c001c432a00bd6428");
        if(!isGen0) {
            return EMPTY;
        } else {
            uint256 index = DateUtils.getDayIndexInYear(2012, month, day);

            (uint256 H, uint256 S, uint256 L) = StringLib.parseCompressedHSL(birthdayColorInHex, index);
            string memory birthdayColor = string(abi.encodePacked("hsl(", StringLib.uintToString(H), ",", StringLib.uintToString(S), "%,", StringLib.uintToString(L), "%)"));
            if(elementType == ElementType.FIRE || elementType == ElementType.WATER) {
                return birthdayColor;
            } else {
                if (elementType == ElementType.EARTH) {
                    H = (H + 360 - 90) % 360; /** maintain H > 30, normally minus 90 */
                    string memory res = string(abi.encodePacked(
                        '<stop offset="0%" stop-color="', birthdayColor, '" />'
                        '<stop offset="100%" stop-color="hsl(', StringLib.uintToString(H), ",", StringLib.uintToString(S), "%,", StringLib.uintToString(L), '%)" />'
                    ));
                    return res;
                } else /** if (elementType == ElementType.WIND) */ {
                    S = (S + 30) % 100;
                    L = (L + 100 - 30) % 100; 

                    string memory line_70 = string(abi.encodePacked(
                        '<stop offset="100%" stop-color="hsl(', StringLib.uintToString(H), ",", StringLib.uintToString(S), "%,", StringLib.uintToString(L), '%)" />'
                    ));
                    string memory line_100 = line_70;
                    string memory res = string(abi.encodePacked(
                        '<stop offset="0%" stop-color="', birthdayColor, '" />',
                        line_70, line_100
                    ));
                    return res; 
                }
            }
        }
    }

    function replaceThemeColor(bool isGen0, ElementType elementType, uint16 month, uint16 day, string memory _str) public pure returns (string memory) {
        string[5] memory colorPatternToReplace = [
            EMPTY, 
            "#e37da2", 
            '<stop offset="0%" stop-color="hsl(211,54.4%,62.2%)" /><stop offset="100%" stop-color="hsl(121,54.4%,62.2%)" />', 
            "#4fb3bf", 
            '<stop offset="0%" stop-color="hsl(49,26%,63%)" />''<stop offset="70%" stop-color="hsl(49,56%,43%)" />''<stop offset="100%" stop-color="hsl(49,56%,43%)" />'
        ];
        string memory pattern = pickValueFromArrayByGenAndElement(colorPatternToReplace, isGen0, elementType);
        string memory replacement = genThemeColorReplacement(isGen0, elementType, month, day);
        return bytes(pattern).length == 0 ? _str : StringLib.replace(_str, pattern, replacement);    
    }

    enum ElementType {
        FIRE, EARTH, WIND, WATER
    }

    struct GenAndElement {
        bool isGen0;
        ElementType elementType;
        string cuspsBody;
        string planetsBody;
        uint16[] planets;
    }

    struct ParamsPart2 {
        string relationLines;
        string centralText;
        uint16 month;
        uint16 day;
    }

    /**
    ElementType's 
     */
    function judgeElementTypeByPlanetDegree(uint16 planetRadian) public pure returns (ElementType) {
        uint16 degree30InRadian = 5236;
        uint16 deg15InRadian = 2618;
        uint16 signIndex = (planetRadian + deg15InRadian) / degree30InRadian;
        if (signIndex == 0 || signIndex == 4 || signIndex == 8) {
            return ElementType.FIRE;
        } else if (signIndex == 1 || signIndex == 5 || signIndex == 9) {
            return ElementType.EARTH;
        } else if (signIndex == 2 || signIndex == 6 || signIndex == 10) {
            return ElementType.WIND;
        } else /** if (signIndex == 3 || signIndex = 7 || signIndex == 11) */ {
            return ElementType.WATER;
        }
    }
}

// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./FireGenerator.sol";

library FireGenerator2 {
    string constant part0 =
    '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="1200" height="1200" id="astro">'
    "<style>"
    ".f1 {"
    "animation: fc1 2s 0.14s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f2 {"
    "animation: fc2 2s 0.28s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f3 {"
    "animation: fc3 2s 0.42s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f4 {"
    "animation: fc4 2s 0.56s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f5 {"
    "animation: fc5 2s 0.7s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f6 {"
    "animation: fc6 2s 0.84s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f7 {"
    "animation: fc7 2s 0.98s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f8 {"
    "animation: fc8 2s 1.12s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f9 {"
    "animation: fc9 2s 1.26s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f10 {"
    "animation: fc10 2s 1.4s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f11 {"
    "animation: fc11 2s 1.54s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f12 {"
    "animation: fc12 2s 1.68s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f13 {"
    "animation: fc13 2s 1.82s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f14 {"
    "animation: fc14 2s 1.96s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f15 {"
    "animation: fc15 2s 2.1s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r1 {"
    "animation: fr1 2s 0.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r2 {"
    "animation: fr2 2s 1s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r3 {"
    "animation: fr3 2s 1.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r4 {"
    "animation: fr4 2s 2s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r5 {"
    "animation: fr5 1.5s 0.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r6 {"
    "animation: fr6 1.5s 1s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r7 {"
    "animation: fr7 1.5s 1.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r8 {"
    "animation: fr8 1.5s 2s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    "@keyframes fc1 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(552px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc2 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(652px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc3 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(564px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc4 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(577px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc5 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(679px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc6 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(563px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc7 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(591px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc8 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(668px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc9 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(546px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc10 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(586px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc11 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(604px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc12 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(641px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc13 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(549px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc14 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(638px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc15 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(629px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fr1 {"
    "0% {"
    "transform: translate(288px, 631px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr2 {"
    "0% {"
    "transform: translate(264px, 599px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr3 {"
    "0% {"
    "transform: translate(257px, 576px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr4 {"
    "0% {"
    "transform: translate(295px, 614px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr5 {"
    "0% {"
    "transform: translate(585px, 611px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr6 {"
    "0% {"
    "transform: translate(611px, 601px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr7 {"
    "0% {"
    "transform: translate(607px, 591px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr8 {"
    "0% {"
    "transform: translate(597px, 626px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "</style>"
    "<defs>"
    '<radialGradient id="darkLight">'
    '<stop offset="0%" stop-color="#484848"/>'
    '<stop offset="3%" stop-color="#1b1b1b"/>'
    '<stop offset="8%" stop-color="#000000"/>'
    "</radialGradient>"
    '<linearGradient id="goldBody" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="#';
    //insert color
    string constant part1 = '"/><stop offset="100%" stop-color="#';
    //insert color
    string constant part2 =
    '"/>'
    "</linearGradient>";

    string constant part2_0_gen0_fire = 
    '<filter id="light0">'
    '<feDropShadow dx="0" dy="0" stdDeviation="2" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light1">'
    '<feDropShadow dx="0" dy="0" stdDeviation="2" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light2">'
    '<feGaussianBlur in="SourceGraphic" stdDeviation="1" />'
    '<feDropShadow dx="0" dy="0" stdDeviation="6" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light3">'
    '<feDropShadow dx="0" dy="0" stdDeviation="10" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light4">'
    '<feGaussianBlur in="SourceGraphic" stdDeviation="1" />'
    '<feDropShadow dx="0" dy="0" stdDeviation="40" flood-color="#e37da2" />'
    '</filter>';
    string constant part2_0_gen0_earth = 
    '<linearGradient id="gradient" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="hsl(211,54.4%,62.2%)" />'
    '<stop offset="100%" stop-color="hsl(121,54.4%,62.2%)" />'
    '</linearGradient>';
    string constant part2_0_gen0_wind = 
    '<linearGradient id="gradient" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="hsl(49,26%,63%)" />'
    '<stop offset="70%" stop-color="hsl(49,56%,43%)" />'
    '<stop offset="100%" stop-color="hsl(49,56%,43%)" />'
    '</linearGradient>';
    string constant part2_0_gen0_water = 
    '<linearGradient id="gradient" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="#f19cbc" />'
    '<stop offset="100%" stop-color="#e37da2" />'
    '</linearGradient>';
    string constant part2_0_gen1 = ""; 
    string constant part2_1 = '<filter id="goo">'
    '<feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur"/>'
    '<feColorMatrix in="blur" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 18 -8" result="goo"/>'
    '<feBlend in="SourceGraphic" in2="goo"/>'
    "</filter>"
    '<clipPath id="centerCut">'
    '<circle cy="600" cx="600" r="140" stroke-width="120"/>'
    '</clipPath>'
    "</defs>";
    string constant part2_2_gen0_fire = '<circle cx="300" cy="300" r="1300" fill="#000">';
    string constant part2_2_gen0_earth = part2_2_gen0_fire;
    string constant part2_2_gen0_wind = '<circle cx="300" cy="300" r="1300" fill="url(#darkLight)">';
    string constant part2_2_gen0_water = part2_2_gen0_fire;
    string constant part2_2_gen1 = part2_2_gen0_earth;

    string constant part2_3 = '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>'
    "</circle>";
    //begin draw border lines
    string constant part_3_0_gen0_fire = '<g stroke="#e37da2" stroke-width="4" filter="url(#light0)">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<line x1="29.999" y1="30" x2="29.999" y2="1170" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="1169.999" y1="30" x2="1169.999" y2="1170" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="600.499" y1="-555.5" x2="600.499" y2="583.5" stroke-linecap="round" stroke-linejoin="round" transform="translate(600.499000, 30.000000) scale(1, -1) rotate(90.000000) translate(-600.499000, -14.000000) " />'
    '<line x1="599.999" y1="600" x2="599.999" y2="1740" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 1170.000000) scale(1, -1) rotate(90.000000) translate(-600.999000, -1170.000000) " />'
    '<g transform="translate(53.499000, 54.000000) rotate(-225.000000) translate(-53.499000, -54.000000) translate(31.999000, 20.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '<g transform="translate(1146.499000, 54.000000) scale(-1, 1) rotate(-225.000000) translate(-1146.499000, -54.000000) translate(1124.999000, 20.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '<g transform="translate(1146.499000, 1146.000000) scale(-1, -1) rotate(-225.000000) translate(-1146.499000, -1146.000000) translate(1124.999000, 1112.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '<g transform="translate(53.499000, 1146.000000) scale(1, -1) rotate(-225.000000) translate(-45.499000, -1138.000000) translate(23.999000, 1104.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '</g>'
    //fire's breath circle
    '<circle cy="600" cx="600" r="457" fill="#000" filter="url(#light4)">'
    '<animate attributeName="opacity" values="0.3;1;0.3" dur="2s" repeatCount="indefinite" filter="url(#light4)" />'
    '</circle>'
    '<circle cy="600" cx="600" r="457" fill="#000" filter="url(#light4)">'
    '<animate attributeName="opacity" values="0.3;1;0.3" dur="2s" repeatCount="indefinite" filter="url(#light4)"/>'
    '</circle>'
    '<circle cy="600" cx="600" r="457" fill="#000" filter="url(#light4)">'
    '<animate attributeName="opacity" values="0.3;1;0.3" dur="2s" repeatCount="indefinite" filter="url(#light4)"/>'
    '</circle>'
    ;
    string constant part_3_0_gen0_earth = 
    '<g stroke="url(#gradient)">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<path d="M30,30 H60 V80 H30 V1120 H60 V1170 H30 V1140 H80 V1170 H1120 V1140 H1170 V1170 H1140 V1120 H1170 V80 H1140 V30 H1170 V60 H1120 V30 H80 V60 H30 V30 Z" stroke-width="4" fill="none" />'
    '</g>';
    string constant part_3_0_gen0_water = 
    '<g stroke="#4fb3bf" stroke-width="4">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<line x1="29.999" y1="89" x2="29.999" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="1169.999" y1="89" x2="1169.999" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="599.999" y1="-481" x2="599.999" y2="541" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 30.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -30.000000) " />'
    '<line x1="599.999" y1="659" x2="599.999" y2="1681" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 1170.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -1170.000000) " />'
    '<g transform="translate(30.000000, 30.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '<g transform="translate(66.000000, 1134.000000) scale(1, -1) translate(-66.000000, -1134.000000) translate(30.000000, 1098.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '<g transform="translate(1134.000000, 66.000000) scale(-1, 1) translate(-1126.000000, -58.000000) translate(1090.000000, 22.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '<g transform="translate(1134.000000, 1134.000000) scale(-1, -1) translate(-1118.000000, -1118.000000) translate(1082.000000, 1082.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '</g>';
    string constant part_3_0_gen0_wind = 
    '<g stroke="url(#gradient)" stroke-width="4">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<line x1="29.999" y1="90" x2="29.998" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="1169.999" y1="90" x2="1169.998" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="599.999" y1="-481" x2="599.998" y2="541" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 30.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -30.000000) " />'
    '<line x1="599.999" y1="659" x2="599.998" y2="1681" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 1170.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -1170.000000) " />'
    '<g transform="translate(29.999000, 30.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '<g transform="translate(1140.499000, 60.000000) scale(-1, 1) translate(-1132.499000, -52.000000) translate(1102.999000, 22.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '<g transform="translate(1140.499000, 1140.000000) scale(-1, -1) translate(-1132.499000, -1132.000000) translate(1102.999000, 1102.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '<g transform="translate(59.499000, 1140.000000) scale(1, -1) translate(-51.499000, -1132.000000) translate(21.999000, 1102.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '</g>';
    
    
    string constant part_3_0_gen1 = 
    '<g stroke="#989898">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none"/>'
    '<path d="M30,30 H60 V80 H30 V1120 H60 V1170 H30 V1140 H80 V1170 H1120 V1140 H1170 V1170 H1140 V1120 H1170 V80 H1140 V30 H1170 V60 H1120 V30 H80 V60 H30 V30 Z" stroke-width="4" fill="none"/>'
    "</g>";

    function svgPart0() public pure returns (string memory) {
        return part0;
    }

    function svgPart1() public pure returns (string memory) {
        return part1;
    }
    function svgPart2(bool gen0, FireGenerator.ElementType elementType) public pure returns (string memory) {
        if (gen0) {
            if(elementType == FireGenerator.ElementType.FIRE) {
                return string(abi.encodePacked(part2, part2_0_gen0_fire, part2_1, part2_2_gen0_fire, part2_3));
            } else if (elementType == FireGenerator.ElementType.EARTH) {
                return string(abi.encodePacked(part2, part2_0_gen0_earth, part2_1, part2_2_gen0_earth, part2_3));
            } else if (elementType == FireGenerator.ElementType.WATER) {
                return string(abi.encodePacked(part2, part2_0_gen0_water, part2_1, part2_2_gen0_earth, part2_3));
            } else /** if (elementType == ElementType.WIND) */ {
                return string(abi.encodePacked(part2, part2_0_gen0_wind, part2_1, part2_2_gen0_wind, part2_3));
            }
        } else /** if(!gen0) */ {
            return string(abi.encodePacked(part2, part2_0_gen1, part2_1, part2_2_gen1, part2_3));
        }
    }
    function svgPart3(bool gen0, FireGenerator.ElementType elementType) public pure returns (string memory) {
        if (gen0) {
            if(elementType == FireGenerator.ElementType.FIRE) {
                return part_3_0_gen0_fire;
            } else if (elementType == FireGenerator.ElementType.EARTH) {
                return part_3_0_gen0_earth;
            } else if (elementType == FireGenerator.ElementType.WATER) {
                return part_3_0_gen0_water;
            } else /** if (elementType == ElementType.WIND) */ {
                return part_3_0_gen0_wind;
            }

        } else /**(!gen0) */ {
            return part_3_0_gen1;
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DateUtils {
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant SECONDS_IN_DAY = 86400;
    uint256 constant SECONDS_IN_YEAR = 31536000;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;
    uint16 constant ORIGIN_YEAR = 1970;
    uint256 constant SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR = 126230400;
    uint256 constant SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999 = 883612800;
    uint256 constant SECONDS_IN_100_YEARS = 3155673600;
    uint256 constant SECONDS_IN_400_YEARS = 12622780800;

    function isLeapYear(uint16 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) private pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function isDateValid(
        uint16 year,
        uint16 month,
        uint16 day
    ) internal view returns (bool) {
        return day > 0 && getDaysInMonth(month, year) >= day;
    }

    function getDaysInMonth(uint16 month, uint16 year)
        internal
        pure
        returns (uint16)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function getDayFromTimestamp(uint256 timestamp)
        internal
        view
        returns (uint16)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;
        uint16 year;
        uint16 month;
        uint16 day;

        // Year
        year = getYear(timestamp);
        buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(month, year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        return day;
    }

    /**
    @dev Convert timestamp to YMD (year, month, day)
    @param _dt Date as timestamp integer
    @return secondsRemaining
   */
    function getUTCSecondsOffsetInDay(uint256 _dt)
        internal
        pure
        returns (uint256 secondsRemaining)
    {
        uint16 year;
        uint8 month;
        uint8 day;
        secondsRemaining = _dt;
        (secondsRemaining, year) = getYearAndSecondsRemaining(secondsRemaining);
        (secondsRemaining, month) = getMonth(secondsRemaining, year);
        (secondsRemaining, day) = getDay(secondsRemaining);
        return secondsRemaining;
    }

    // functions to calculate year, month, or day from timestamp
    function getYearAndSecondsRemaining(uint256 _secondsRemaining)
        private
        pure
        returns (uint256 secondsRemaining, uint16 year)
    {
        uint256 res;
        uint32 secondsInThisYear;

        secondsRemaining = _secondsRemaining;
        year = 1970;

        if (secondsRemaining < (2 * SECONDS_IN_YEAR)) {
            res = secondsRemaining / SECONDS_IN_YEAR;
            secondsRemaining -= res * SECONDS_IN_YEAR;
            year += uint16(res);
        } else {
            secondsRemaining -= 2 * SECONDS_IN_YEAR;
            year = 1972;

            if (
                secondsRemaining >= SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999
            ) {
                secondsRemaining -= SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999;
                year += 28;

                res = secondsRemaining / SECONDS_IN_400_YEARS;
                secondsRemaining -= res * SECONDS_IN_400_YEARS;
                year += uint16(res * 400);

                secondsInThisYear = uint32(getSecondsInYear(year));

                if (secondsRemaining >= secondsInThisYear) {
                    secondsRemaining -= secondsInThisYear;
                    year += 1;
                }

                if (!isLeapYear(year)) {
                    res = secondsRemaining / SECONDS_IN_100_YEARS;
                    secondsRemaining -= res * SECONDS_IN_100_YEARS;
                    year += uint16(res * 100);
                }
            }

            res = secondsRemaining / SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR;
            secondsRemaining -= res * SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR;
            year += uint16(res * 4);

            secondsInThisYear = uint32(getSecondsInYear(year));

            if (secondsRemaining >= secondsInThisYear) {
                secondsRemaining -= secondsInThisYear;
                year += 1;
            }

            if (!isLeapYear(year)) {
                res = secondsRemaining / SECONDS_IN_YEAR;
                secondsRemaining -= res * SECONDS_IN_YEAR;
                year += uint16(res);
            }
        }
    }

    function getSecondsInYear(uint16 _year) private pure returns (uint256) {
        if (isLeapYear(_year)) {
            return (SECONDS_IN_YEAR + SECONDS_IN_DAY);
        } else {
            return SECONDS_IN_YEAR;
        }
    }

    function getYear(uint256 timestamp) private pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 _secondsRemaining, uint16 _year)
        private
        pure
        returns (uint256 secondsRemaining, uint8 month)
    {
        uint8[13] memory monthDayMap;
        uint32[13] memory monthSecondsMap;

        secondsRemaining = _secondsRemaining;

        if (isLeapYear(_year)) {
            monthDayMap = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
            monthSecondsMap = [
                0,
                2678400,
                5184000,
                7862400,
                10454400,
                13132800,
                15724800,
                18403200,
                21081600,
                23673600,
                26352000,
                28944000,
                31622400
            ];
        } else {
            monthDayMap = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
            monthSecondsMap = [
                0,
                2678400,
                5097600,
                7776000,
                10368000,
                13046400,
                15638400,
                18316800,
                20995200,
                23587200,
                26265600,
                28857600,
                31536000
            ];
        }

        for (uint8 i = 1; i < 13; i++) {
            if (secondsRemaining < monthSecondsMap[i]) {
                month = i;
                secondsRemaining -= monthSecondsMap[i - 1];
                break;
            }
        }
    }

    function getDay(uint256 _secondsRemaining)
        private
        pure
        returns (uint256 secondsRemaining, uint8 day)
    {
        uint256 res;

        secondsRemaining = _secondsRemaining;

        res = secondsRemaining / SECONDS_IN_DAY;
        secondsRemaining -= res * SECONDS_IN_DAY;
        day = uint8(res + 1);
    }

    function getDayIndexInYear(uint16 year, uint16 month, uint256 day)
        internal
        pure
        returns (uint256 index) 
    {
        index = 0;
        for (uint16 i = 1; i < month; i++) { 
            index += getDaysInMonth(i, year);
        }
        index += day - 1;
    }
}