//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LW77x7.sol";
import './LTNT.sol';
import 'base64-sol/base64.sol';
import './lib/Rando.sol';
import './LTNTFont.sol';


/**

          ___  ___      ___        __   __        __  
|     /\   |  |__  |\ |  |   |  | /  \ |__) |__/ /__` 
|___ /~~\  |  |___ | \|  |  .|/\| \__/ |  \ |  \ .__/ 
                                                      
"00x0", latent.works, 2022


*/


contract LW00x0 is ERC1155, ERC1155Supply, ERC1155Holder, Ownable, ReentrancyGuard, LTNTIssuer {

    // Orientation enum for artworks
    enum Orientation{LANDSCAPE, PORTRAIT}

    // Comp info
    struct Comp {
        uint id;
        address creator;
        string seed;
        string image;
        Orientation orientation;
        uint editions;
        uint available;
    }

    event CompCreated(uint indexed comp_id, address indexed creator);

    string public constant NAME = unicode"Latent Works · 00x0";
    string public constant DESCRIPTION = "latent.works";
    uint public constant PRICE = 0.07 ether;
    
    LTNT public immutable _ltnt;
    LW77x7 public immutable _77x7;
    LW77x7_LTNTIssuer public immutable _77x7_ltnt_issuer;
    LW00x0_Meta public immutable _00x0_meta;

 
    uint private _comp_ids;
    mapping(uint => uint[]) private _comp_works;
    mapping(uint => address) private _comp_creators;


    constructor(address seven7x7_, address seven7x7_ltnt_issuer_, address ltnt_) ERC1155("") {

        _77x7 = LW77x7(seven7x7_);
        _77x7_ltnt_issuer = LW77x7_LTNTIssuer(seven7x7_ltnt_issuer_);
        _ltnt = LTNT(ltnt_);

        LW00x0_Meta meta_ = new LW00x0_Meta(address(this), seven7x7_);
        _00x0_meta = LW00x0_Meta(address(meta_));

    }


    /// @dev require function to check if an address is the 77x7 contract
    function _req77x7Token(address address_) private view {
        require(address_ == address(_77x7), 'ONLY_77X7_ACCEPTED');
    }


    /// @dev return issuer information for LTNT passports
    function issuerInfo(uint, LTNT.Param memory param_) public view override returns(LTNT.IssuerInfo memory){

        return LTNT.IssuerInfo(
            '00x0', getImage(param_._uint, true, true)
        );

    }

    /// @dev override for supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev recieves a batch of 77x7 works and creates a 00x from them as well as issues a LTNT for each work
    function onERC1155BatchReceived(address, address from_, uint[] memory ids_, uint[] memory, bytes memory) public override returns(bytes4){
        
        _req77x7Token(_msgSender());
        require(ids_.length > 1 && ids_.length <= 7, 'ID_COUNT_OUT_OF_RANGE');

        uint comp_id_ = _create(from_, ids_);
        uint id_;

        for(uint i = 0; i < ids_.length; i++){
            id_ = _77x7_ltnt_issuer.issueTo(from_, LTNT.Param(ids_[i], from_, '', true), true);
            _ltnt.stamp(id_, LTNT.Param(comp_id_, from_, '', false));
        }

        return super.onERC1155BatchReceived.selector;

    }
    
    /// @dev recieves a single 77x7 work and issues a LTNT for it
    function onERC1155Received(address, address from_, uint256 id_, uint256, bytes memory) public override returns(bytes4){
        _req77x7Token(_msgSender());
        _77x7_ltnt_issuer.issueTo(from_, LTNT.Param(id_, from_, '', false), true);
        return super.onERC1155Received.selector;
    }

    /// @dev internal function to create a comp for a given set of 77x7 works
    function _create(address for_, uint[] memory works_) private returns(uint) {

        require((works_.length > 1 && works_.length <= 7), "MIN_2_MAX_7_WORKS");

        _comp_ids++;
        _comp_works[_comp_ids] = works_;
        _comp_creators[_comp_ids] = for_;

        emit CompCreated(_comp_ids, for_);
        
        _mintFor(for_, _comp_ids);
        return _comp_ids;

    }

    /// @dev internal mint function
    function _mintFor(address for_, uint comp_id_) private {
        _mint(for_, comp_id_, 1, "");
    }

    /// @dev mint yeah
    function mint(uint comp_id_) public payable nonReentrant {

        require(msg.sender != _comp_creators[comp_id_], 'COMP_CREATOR');
        require(msg.value == PRICE, "INVALID_VALUE");
        require(getAvailable(comp_id_) > 0, "UNAVAILABLE");
        require(_comp_creators[comp_id_] != msg.sender, "NO_CREATOR_MINT");
        
        address owner_ = owner();
        uint each_ = msg.value / 2;
        (bool creator_sent_,) =  _comp_creators[comp_id_].call{value: each_}("");
        (bool owner_sent_,) =  owner_.call{value: each_}("");
        require((creator_sent_ && owner_sent_), "INTERNAL_ETHER_TX_FAILED");

        _mintFor(msg.sender, comp_id_);
        _ltnt.issueTo(msg.sender, LTNT.Param(comp_id_, msg.sender, '', false), true);

    }

    /// @dev get the number of total editions for a given comp
    function getEditions(uint comp_id_) public view returns(uint) {
        return _comp_works[comp_id_].length;
    }

    /// @dev get the creator adress of a given comp id
    function getCreator(uint comp_id_) public view returns(address){
        return _comp_creators[comp_id_];
    }

    /// @dev get the total available editions left for comp
    function getAvailable(uint comp_id_) public view returns(uint){
        return _comp_works[comp_id_].length - totalSupply(comp_id_);
    }


    /// @dev get the 77x7 work IDs used to create a given comp
    function getWorks(uint comp_id_) public view returns(uint[] memory){
        return _comp_works[comp_id_];
    }

    /// @dev get the image of a given comp
    function getImage(uint comp_id_, bool mark_, bool encode_) public view returns(string memory output_){
        require(totalSupply(comp_id_) > 0, 'DOES_NOT_EXIST');
        return _00x0_meta.getImage(comp_id_, mark_, encode_);
    }

    function getComps(uint limit_, uint page_, bool ascending_) public view returns(LW00x0.Comp[] memory){

        uint count_ = _comp_ids;

        if(limit_ < 1 && page_ < 1){
            limit_ = count_;
            page_ = 1;
        }

        LW00x0.Comp[] memory comps_ = new LW00x0.Comp[](limit_);
        uint i;

        if(ascending_){
            // ASCENDING
            uint id = page_ == 1 ? 1 : ((page_-1)*limit_)+1;
            while(id <= count_ && i < limit_){
                comps_[i] = getComp(id);
                ++i;
                ++id;
            }
        }
        else {
            /// DESCENDING
            uint id = page_ == 1 ? count_ : count_ - (limit_*(page_-1));
            while(id > 0 && i < limit_){
                comps_[i] = getComp(id);
                ++i;
                --id;
            }

        }

        return comps_;


    }


    /// @dev get the comp struct for a given comp ID
    function getComp(uint comp_id_) public view returns(LW00x0.Comp memory){

        return LW00x0.Comp(
            comp_id_,
            getCreator(comp_id_),
            _00x0_meta.getSeed(comp_id_, ''),
            getImage(comp_id_, true, true),
            _00x0_meta.getOrientation(comp_id_),
            getEditions(comp_id_),
            getAvailable(comp_id_)
        );

    }

    /// @dev get total number of comps created
    function getCompCount() public view returns(uint){
        return _comp_ids;
    }

    /// @dev return the metadata uri for a given url
    function uri(uint comp_id_) public view override returns(string memory){
        return _00x0_meta.getJSON(comp_id_);
    }


    // Required overrides

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Supply){
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override (ERC1155) {
        super._mint(account, id, amount, data);
    }


    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override (ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }


    function _burn(address account, uint256 id, uint256 amount) internal override (ERC1155) {
        super._burn(account, id, amount);
    }


    function _burnBatch(address to, uint256[] memory ids, uint256[] memory amounts) internal override (ERC1155) {
        super._burnBatch(to, ids, amounts);
    }


}






contract LW00x0_Meta {

    LW00x0 private _00x0;
    LW77x7 private _77x7;
    
    string private _easing = 'keyTimes="0; 0.33; 0.66; 1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1;"';    
    string private _noise = 'data:@file/png;base64,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';

    // Compinfo for passing to the comp creator
    struct CompInfo {
        string id;
        string id_string;
        bool mark;
        string seed;
        string seed0;
        string seed1;
        string seed2;
        string seed3;
        uint[] works;
        bytes defs;
        bytes ani_elements;
        bytes elements;
        uint left;
        uint right;
        LW00x0.Orientation orientation;
        string width_string;
        string height_string;
        string[2] pos;
        uint start;
        uint last_left;
        uint last_right;
        bytes begin_t;
        bytes translate;
        bytes scale;
    }

    constructor(address zero0x0_, address seven7x7_){
        _00x0 = LW00x0(zero0x0_);
        _77x7 = LW77x7(seven7x7_);
    }

    /**
    
    SEEDS
    
     */
    function _generateSeed(address salt_, uint[] memory works_, string memory append_) private pure returns(string memory){
        uint salt_uint_ = (uint256(uint160(salt_)))/10000000000000000000000000000000000000;
        return string(abi.encodePacked(Strings.toString(salt_uint_+(works_[0]+works_[1])*(works_[0]+works_[1])*(77*works_.length)), append_));
    }

    function getSeed(uint comp_id_, string memory append_) public view returns(string memory){
        uint[] memory works_ = _00x0.getWorks(comp_id_);
        address salt_ = _00x0.getCreator(comp_id_);
        return _generateSeed(salt_, works_, append_);
    }


    /**
    
    ORIENTATION

     */
    function _generateOrientation(string memory seed_) private pure returns(LW00x0.Orientation){
        return Rando.number(seed_, 0, 99) > 50 ? LW00x0.Orientation.LANDSCAPE : LW00x0.Orientation.PORTRAIT;
    }

    function getOrientation(uint comp_id_) public view returns(LW00x0.Orientation){
        string memory seed_ = _generateSeed(_00x0.getCreator(comp_id_), _00x0.getWorks(comp_id_), '');
        return _generateOrientation(seed_);
    }


    /**
    
    COMPS
    
     */

    function _generateComp(address salt_, uint[] memory works_) private pure returns(CompInfo memory) {

        return CompInfo(
            '',
            '',
            false,
            _generateSeed(salt_, works_, ''),
            '',
            '',
            '',
            _generateSeed(salt_, works_, 'rand'),
            works_,
            '',
            '',
            '',
            0,
            0,
            _generateOrientation(_generateSeed(salt_, works_, '')),
            '',
            '',
            ['', ''],
            0,
            0,
            0,
            '',
            '',
            ''
        );

    }


    function getImage(uint comp_id_, bool mark_, bool encode_) public view returns(string memory) {

        CompInfo memory comp_ = _generateComp(_00x0.getCreator(comp_id_), _00x0.getWorks(comp_id_));

        comp_.id = Strings.toString(comp_id_);
        comp_.mark = mark_;

        return _generateImage(comp_, encode_);
        
    }

    function previewImage(address salt_, uint[] memory works_) public view returns(string memory){

        require((works_.length > 1 && works_.length <= 7), "MIN_2_MAX_7_WORKS");
        for(uint i = 0; i < works_.length; i++){
            require(_77x7.exists(works_[i]), 'WORK_DOES_NOT_EXIST');
        }

        CompInfo memory comp_ = _generateComp(salt_, works_);
        comp_.id = 'PRE';
        comp_.mark = true;

        return _generateImage(comp_, true);

    }

    function _generateImage(CompInfo memory comp_, bool encode_) private view returns(string memory){

        comp_.start = (700/comp_.works.length);
        comp_.last_left = Rando.number(comp_.seed1, comp_.start-100, comp_.start);
        comp_.last_right = Rando.number(comp_.seed2, comp_.start-100, comp_.start);
        
        comp_.pos[0] = Strings.toString(Rando.number(comp_.seed, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 800 : 500));
        comp_.pos[1] = Strings.toString(Rando.number(comp_.seed1, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 500 : 800));

        comp_.width_string = comp_.orientation == LW00x0.Orientation.LANDSCAPE ? '1000' : '700';
        comp_.height_string = comp_.orientation == LW00x0.Orientation.LANDSCAPE ? '700' : '1000';
        
        for(uint i = 0; i < comp_.works.length; i++) {
            
            comp_.seed0 = string(abi.encodePacked(comp_.seed, Strings.toString(i)));
            comp_.seed1 = string(abi.encodePacked(comp_.seed, abi.encodePacked(comp_.seed0, 'left')));
            comp_.seed2 = string(abi.encodePacked(comp_.seed, abi.encodePacked(comp_.seed0, 'right')));

            comp_.id_string = Strings.toString(i+1);
            
            comp_.left = Rando.number(comp_.seed1, comp_.last_left/10, 1000);
            comp_.right = Rando.number(comp_.seed2, comp_.last_right/2, 1000);
            
            comp_.defs = abi.encodePacked(comp_.defs,
            '<clipPath id="clip',comp_.id_string,'"><polygon points="0,',Strings.toString(comp_.last_left),' 0,',Strings.toString(comp_.left),' 1000,',Strings.toString(comp_.right),' 1000,',Strings.toString(comp_.last_right),'">',
            '</polygon></clipPath>');

            
            comp_.elements = abi.encodePacked(comp_.elements,
            '<rect fill="', _77x7.getColor(comp_.works[i], Rando.number(comp_.seed0, 1, 7)),'" y="0" x="0" height="1000" width="1000" clip-path="url(#clip',comp_.id_string,')">',
            '</rect>'
            );

            comp_.begin_t = abi.encodePacked(Strings.toString(Rando.number(comp_.seed1, 100, 700)),' ',Strings.toString(Rando.number(comp_.seed2, 100, 700)));
            comp_.translate = abi.encodePacked(comp_.begin_t, ';', Strings.toString(Rando.number(comp_.seed1, 10, 800)),' ', Strings.toString(Rando.number(comp_.seed2, 10, 800)),';', Strings.toString(Rando.number(comp_.seed2, 100, 1000)),' ', Strings.toString(Rando.number(comp_.seed1, 400, 800)),';',comp_.begin_t);
            comp_.scale = abi.encodePacked('1; 0.', Strings.toString(Rando.number(comp_.seed1, 1, 9)),'; 0.',Strings.toString(Rando.number(comp_.seed2, 1, 9)),'; 1');

            comp_.ani_elements = abi.encodePacked(comp_.ani_elements,
            '<rect fill="', _77x7.getColor(comp_.works[i], Rando.number(comp_.seed0, 1, 7)),'" y="0" x="0" height="1000" width="1000" clip-path="url(#clip',comp_.id_string,')">',
            '<animateTransform ',_easing,' attributeName="transform" type="scale" values="',comp_.scale,'" begin="0s" dur="',Strings.toString(Rando.number(comp_.seed2, 50, 100)),'s" repeatCount="indefinite"/>',
            '</rect>'
            );

            comp_.last_left = comp_.left;
            comp_.last_right = comp_.right;

        }

        comp_.pos[0] = Strings.toString(Rando.number(comp_.seed, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 800 : 500));
        comp_.pos[1] = Strings.toString(Rando.number(comp_.seed1, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 500 : 800));
        
        bytes memory output_ = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',comp_.width_string, ' ', comp_.height_string, '" preserveAspectRatio="xMinYMin meet">',
            '<defs>',
            '<pattern id="noise" x="0" y="0" width="51" height="51" patternUnits="userSpaceOnUse"><image opacity="0.2" width="51" height="51" href="',_noise,'"/></pattern>',
            '<g id="main" transform="translate(-5 -5) scale(1.2)" opacity="0.8">',
            comp_.elements,
            '</g>',
            '<g id="main-ani" transform="translate(-5 -5) scale(1.2)" opacity="0.8">',
            comp_.ani_elements,
            '</g>',
            '<filter id="blur" x="0" y="0"><feGaussianBlur in="SourceGraphic" stdDeviation="100"/></filter>',
            '<rect id="bg" height="',comp_.height_string,'" width="',comp_.width_string,'" x="0" y="0"/><clipPath id="clip"><use href="#bg"/></clipPath>',
            comp_.defs,
            '</defs>'
        );
        
        output_ = abi.encodePacked(
            output_,
            '<g clip-path="url(#clip)">',
            '<use href="#bg" fill="white"/>',
            '<use href="#bg" fill="',_77x7.getColor(comp_.works[0], 1),'" opacity="0.25"/>',
            '<use href="#main" filter="url(#blur)" transform="rotate(90, 500, 500)"/>',
            '<use href="#main-ani" filter="url(#blur)" transform="scale(0.',Strings.toString(Rando.number(comp_.seed0, 5, 9)),') rotate(90, 500, 500)"/>',
            '<use href="#main-ani" filter="url(#blur)" transform="scale(0.',Strings.toString(Rando.number(comp_.seed0, 3, 6)),') translate(',comp_.pos[0],', ',comp_.pos[1],')"/>',
            comp_.mark ? _getMark(comp_) : bytes(''),
            '<use href="#bg" fill="url(#noise)"/>',
            '</g>',
            '</svg>'
        );

        if(encode_)
            return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(output_)));

        return string(output_);

    }


    function _getMark(CompInfo memory comp_) private pure returns(bytes memory){
        
        bytes memory leading_zeroes_;
        if(bytes(comp_.id).length == 1)
            leading_zeroes_ = '00';
        else if(bytes(comp_.id).length == 2)
            leading_zeroes_ = '0';

        string memory lift_text_ = Strings.toString((comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 700 : 1000)-10);
        return abi.encodePacked('<style>.txt{font: normal 12px monospace;fill: white; letter-spacing:0.1em;}</style><rect width="115" height="30" x="-2" y="',Strings.toString((comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 700 : 1000)-28),'" fill="#000" class="box"></rect><text x="12" y="',lift_text_,'" class="txt">#', leading_zeroes_, comp_.id,unicode' · ', '00x0</text><text x="123" y="',lift_text_,'" class="txt">',comp_.seed0,'</text>');
        
    }


    function getJSON(uint comp_id_) public view returns(string memory){
        
        LW00x0.Comp memory comp_ = _00x0.getComp(comp_id_);
        bytes memory meta_ = abi.encodePacked(
        '{',
            '"name": "00x0 comp #',Strings.toString(comp_id_),'", ',
            '"description": "latent.works", ',
            '"image": "',comp_.image,'", '
            '"attributes": [',
            '{"trait_type": "orientation", "value":"',comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 'Landscape' : 'Portrait','"},',
            '{"trait_type": "base", "value":',Strings.toString(_00x0.getWorks(comp_id_).length),'}',
            ']',
        '}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(meta_)));

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import './LTNT.sol';
import 'base64-sol/base64.sol';
import './lib/Rando.sol';

/**

          ___  ___      ___        __   __        __  
|     /\   |  |__  |\ |  |   |  | /  \ |__) |__/ /__` 
|___ /~~\  |  |___ | \|  |  .|/\| \__/ |  \ |  \ .__/ 
                                                      
"77x7", troels_a, 2021


*/

contract LW77x7 is ERC1155, ERC1155Supply, Ownable {

    using Counters for Counters.Counter;

    // Constants
    string public constant NAME = "Latent Works \xc2\xb7 77x7";
    string public constant DESCRIPTION = "latent.works";
    uint public constant MAX_WORKS = 77;
    uint public constant MAX_EDITIONS = 7;

    // Works
    Counters.Counter private _id_tracker;
    uint private _released = 0;
    uint private _editions = 0;
    uint private _minted = 0;
    uint private _curr_edition = 0;
    uint private _price = 0.07 ether;
    mapping(uint => string) private _seeds;
    mapping(uint => mapping(uint => address)) private _minters;
    mapping(uint => mapping(uint => uint)) private _timestamps;

    struct Work {
      uint token_id;
      string name;
      string description;
      string image;
      string[7] iterations;
      string[7] colors;
    }


    // Canvas
    mapping(uint256 => string[]) private _palettes;

    constructor() ERC1155("") {

      _palettes[1] = ["#82968c","#6a706e","#ffd447","#ff5714","#170312","#0cf574","#f9b4ed"];
      _palettes[2] = ["#f59ca9","#775253","#01fdf6","#cff27e","#294d4a","#0cf574","#0e103d"];
      _palettes[3] = ['rgba(90, 232, 89, 0.706)', 'rgba(255, 98, 98, 0.706)', 'rgba(79, 42, 109, 0.706)', 'rgba(0, 255, 208, 0.769)', 'pink', '#888', 'black'];

    }


    // State
    function getAvailable() public view returns (uint){
      return (_released - _minted);
    }

    function getMinted() public view returns (uint){
      return _minted;
    }

    function getEditions() public view returns(uint){
      return _editions;
    }

    function getCurrentEdition() public view returns(uint){
        return _curr_edition;
    }
    

    // Minting
    function releaseEdition(address[] memory to) public onlyOwner {
      require(_editions < MAX_EDITIONS, 'MAX_EDITIONS_RELEASED');
      _released = _released+MAX_WORKS;
      _editions++;
      for(uint256 i = 0; i < to.length; i++){
        _mintTo(to[i]);
      }
    }

    function mint() public payable returns (uint) {
      require(msg.value >= _price, "VALUE_TOO_LOW");
      require((getAvailable() > 0), "NOT_AVAILABLE");
      return _mintTo(msg.sender);
    }

    function _mintTo(address to) private returns(uint){
      
      _id_tracker.increment();

      uint256 token_id = _id_tracker.current();

      if(token_id == 1)
        _curr_edition++;

      uint edition = getCurrentEdition();

      if(edition == 1){
        _seeds[token_id] = string(abi.encodePacked(Strings.toString(token_id), block.timestamp, block.difficulty));
      }

      _mint(to, token_id, 1, "");
      _minted++;
      _minters[token_id][edition] = to;
      _timestamps[token_id][edition] = block.timestamp;

      if(token_id == MAX_WORKS){
        _id_tracker.reset();
      }

      return token_id;

    }


    // Media and metadata
    function _getIterationSeed(uint token_id, uint iteration) private view returns(string memory){
      return string(abi.encodePacked(_seeds[token_id], Strings.toString(iteration)));
    }

    function _getPaletteIndex(uint token_id) private view returns(uint) {
      return Rando.number(string(abi.encodePacked(_seeds[token_id], 'P')), 1, 3);
    }

    function getPalette(uint token_id) public view returns(string[] memory){
      uint index = _getPaletteIndex(token_id);
      return _palettes[index];
    }

    function getColor(uint token_id, uint iteration) public view returns(string memory){
      string[] memory palette = getPalette(token_id);
      return palette[Rando.number(string(abi.encodePacked(_getIterationSeed(token_id, iteration), 'C')), 1, 7)];
    }

    function getMinter(uint token_id, uint edition) public view returns(address){
      return _minters[token_id][edition];
    }

    function getWork(uint token_id) public view returns(Work memory){
      
      string[7] memory iterations;
      string[7] memory colors;

      uint supply = totalSupply(token_id);
      uint i = 0;
      while(i < supply){
        iterations[i] = getSVG(token_id, i+1, true);
        i++;
      }

      i = 0;
      while(i < supply){
        colors[i] = getColor(token_id, i);
        i++;
      }

      return Work(
        token_id,
        string(abi.encodePacked("Latent Work #", Strings.toString(token_id))),
        DESCRIPTION,
        getSVG(token_id, supply, true),
        iterations,
        colors
      );

    }

    function _getElement(uint token_id, uint iteration, string memory filter) private view returns(string memory){
      
      string memory svgSeed = _getIterationSeed(token_id, iteration);
      string memory C = getColor(token_id, iteration);
      uint X = Rando.number(string(abi.encodePacked(svgSeed, 'X')), 10, 90);
      uint Y = Rando.number(string(abi.encodePacked(svgSeed, 'Y')), 10, 90);
      uint R = Rando.number(string(abi.encodePacked(svgSeed, 'R')), 5, 70);

      return string(abi.encodePacked('<circle cx="',Strings.toString(X),'%" cy="',Strings.toString(Y),'%" r="',Strings.toString(R),'%" filter="url(#',filter,')" fill="',C,'"></circle>'));

    }


    function _getWatermark(uint token_id, uint iteration) private view returns (string memory) {
      return string(abi.encodePacked('<style>.txt{font: normal 12px monospace;fill: white;}</style><rect width="90" height="30" x="0" y="747" fill="#000" class="box"></rect><text x="12" y="766" class="txt">#',(token_id < 10 ? string(abi.encodePacked('0', Strings.toString(token_id))) : Strings.toString(token_id)),' \xc2\xb7 ',Strings.toString(iteration),'/',Strings.toString(MAX_EDITIONS),'</text><text x="103" y="766" class="txt">',Strings.toString(_timestamps[token_id][iteration]),'</text>'));
    }


    function getSVG(uint256 token_id, uint iteration, bool mark) public view returns (string memory){

        require(iteration <= totalSupply(token_id), 'EDITION_NOT_MINTED');

        string[4] memory parts;

        string memory elements = string(abi.encodePacked(_getElement(token_id, 70, "f1"), _getElement(token_id, 700, "f1")));
        uint i;
        while(i < iteration){
          elements = string(abi.encodePacked(elements, _getElement(token_id, i, "f0")));
          i++;
        }

        uint size = 777;
        string memory view_box_size = Strings.toString(size);
        string memory blur = Strings.toString(size/(iteration+1));

        parts[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ',view_box_size,' ',view_box_size,'"><defs><rect id="bg" width="100%" height="100%" fill="#fff" /><clipPath id="clip"><use xlink:href="#bg"/></clipPath><filter id="f0" width="300%" height="300%" x="-100%" y="-100%"><feGaussianBlur in="SourceGraphic" stdDeviation="',blur,'"/></filter><filter id="f1" width="300%" height="300%" x="-100%" y="-100%"><feGaussianBlur in="SourceGraphic" stdDeviation="700"/></filter></defs><rect width="100%" height="100%" fill="#fff" />'));
        parts[1] = string(abi.encodePacked('<g clip-path="url(#clip)"><use xlink:href="#bg"/>', elements, '</g>'));
        parts[2] = mark ? _getWatermark(token_id, iteration) : '';
        parts[3] = '</svg>';

        string memory output = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]))))));

        return output;

    }

    function uri(uint256 token_id) virtual public view override returns (string memory) {
        
        require(exists(token_id), 'INVALID_ID');
        Work memory work = getWork(token_id);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', work.name, '", "description": "', work.description, '", "image": "', work.image, '"}'))));

        return string(abi.encodePacked('data:application/json;base64,', json));

    }

    // Balance
    function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
    }


    // Required overrides

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Supply){
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override (ERC1155) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override (ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(address account, uint256 id, uint256 amount) internal override (ERC1155) {
        super._burn(account, id, amount);
    }

    function _burnBatch(address to, uint256[] memory ids, uint256[] memory amounts) internal override (ERC1155) {
        super._burnBatch(to, ids, amounts);
    }

}




contract LW77x7_LTNTIssuer is LTNTIssuer, Ownable {

  LW77x7 public immutable _77x7;
  LTNT public immutable _ltnt;
  address private _caller;

  mapping(uint => uint) private _iterations;

  constructor(address seven7x7_, address ltnt_) {
    _77x7 = LW77x7(seven7x7_);
    _ltnt = LTNT(ltnt_);
  }

  function issuerInfo(uint id_, LTNT.Param memory param_) public override view returns(LTNT.IssuerInfo memory){
    return LTNT.IssuerInfo(
      '77x7', _77x7.getSVG(param_._uint, _iterations[id_], true)
    );
  }

  function issueTo(address to_, LTNT.Param memory param_, bool stamp_) public returns(uint) {
    require(msg.sender == _caller, 'ONLY_CALLER');
    uint id_ = _ltnt.issueTo(to_, param_, stamp_);
    _iterations[id_] = 7;
    return id_;
  }

  function setCaller(address caller_) public onlyOwner {
    _caller = caller_;
  }

  function setIteration(uint id_, uint iteration_) public {
    require(msg.sender == _ltnt.ownerOf(id_), 'NOT_OWNER');
    require(iteration_ > 0 && iteration_ < 8, 'ITERATION_OUT_OF_RANGE');
    _iterations[id_] = iteration_;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LTNTFont.sol";
import "base64-sol/base64.sol";


//////////////////////////////////
//
//
// LTNT
// Passport NFTs for Latent Works
//
//
//////////////////////////////////


/// @title LTNT
/// @author troels_a

contract LTNT is ERC721, Ownable {
    
    struct Param {
        uint _uint;
        address _address;
        string _string;
        bool _bool;
    }

    struct IssuerInfo {
        string name;
        string image;
    }

    struct Issuer {
        address location;
        Param param;
    }

    event Issued(uint indexed id, address indexed to);
    event Stamped(uint indexed id, address indexed stamper);

    LTNT_Meta private _ltnt_meta;

    address[] private _issuers; ///@dev array of addresses registered as issuers
    mapping(uint => mapping(address => bool)) private _stamps; ///@dev (ltnt => (issuer => is stamped?))
    mapping(uint => mapping(address => Param)) private _params; ///@dev (ltnt => (issuer => stamp parameters));
    mapping(uint => Issuer) private _issuer_for_id; ///@dev (ltnt => issuer) - the Issuer for a given LTNT
    
    uint private _ids; ///@dev LTNT _id counter

    /// @dev pass address of onchain fonts to the constructor
    constructor(address regular_, address italic_) ERC721("Latents", "LTNT"){

        LTNT_Meta ltnt_meta_ = new LTNT_Meta(address(this), regular_, italic_);
        _ltnt_meta = LTNT_Meta(address(ltnt_meta_));

    }




    /// @notice Require a given address to be a registered issuer
    /// @param caller_ the address to check for issuer privilegies
    function _reqOnlyIssuer(address caller_) private view {
        require(isIssuer(caller_), 'ONLY_ISSUER');
    }



    /// @notice Issue a token to the address
    /// @param to_ the address to issue the LTNT to
    /// @param param_ a Param struct of parameters associated with the token
    /// @param stamp_ boolean determining wether the newly issued LTNT should be stamped by the issuer
    /// @return uint the id of the newly issued LTNT
    function issueTo(address to_, Param memory param_, bool stamp_) public returns(uint){ _reqOnlyIssuer(msg.sender);
        
        _ids++;
        _safeMint(to_, _ids);
        _issuer_for_id[_ids] = Issuer(msg.sender, param_);

        emit Issued(_ids, to_);
        
        if(stamp_)
            _stamp(_ids, msg.sender, param_);

        return _ids;

    }



    /// @dev Lets a registered issuer stamp a given LTNT
    /// @param id_ the ID of the LTNT to stamp
    /// @param param_ a Param struct with any associated params
    function stamp(uint id_, Param memory param_) public { _reqOnlyIssuer(msg.sender);
        _stamp(id_, msg.sender, param_);
    }



    /// @dev internal stamping mechanism
    /// @param id_ the id of the LTNT to stamp
    /// @param issuer_ the address of the issuer stamping the LTNT
    /// @param param_ a Param struct with stamp parameters
    function _stamp(uint id_, address issuer_, Param memory param_) private {
        _stamps[id_][issuer_] = true;
        _params[id_][issuer_] = param_;
        emit Stamped(_ids, issuer_);
    }

    /// @dev checks if a given id_ is stamped by address_
    /// @param id_ the ID of the LTNT to check
    /// @param address_ the address of the stamper
    /// @return bool indicating wether LTNT is stamped
    function hasStamp(uint id_, address address_) public view returns(bool){
        return _stamps[id_][address_];
    }

    /// @dev get params for a given stamp on a LTNT
    /// @param id_ the id of the LTNT
    /// @param address_ the address of the stamper
    /// @return Param the param to return
    function getStampParams(uint id_, address address_) public view returns(Param memory){
        return _params[id_][address_];
    }

    /// @dev Get the addresses of the issuers that have stamped a given LTNT
    /// @param id_ the ID of the LTNT to fetch stamps for
    /// @return addresses an array of issuer addresses that have stamped the LTNT
    function getStamps(uint id_) public view returns(address[] memory){
        
        // First count the stamps
        uint count;
        for(uint i = 0; i < _issuers.length; i++){
            if(_stamps[id_][_issuers[i]])
                ++count;
        }

        // Init a stamps_ array with the right length from count_
        address[] memory stamps_ = new address[](count);

        // Loop over the issuers and save stampers in stamps_
        count = 0;
        for(uint i = 0; i < _issuers.length; i++){
            if(_stamps[id_][_issuers[i]]){
                stamps_[count] = _issuers[i];
                ++count;
            }
        }

        return stamps_;

    }

    /// @dev list all issuer addresses
    /// @return addresses list of all issuers
    function getIssuers() public view returns(address[] memory){
        return _issuers;
    }

    /// @dev get the issuer of a LTNT
    function getIssuerFor(uint id_) public view returns(LTNT.Issuer memory){
        return _issuer_for_id[id_];
    }

    /// @dev set the meta contract
    /// @param address_ the address of the meta contract
    function setMetaContract(address address_) public onlyOwner {
        _ltnt_meta = LTNT_Meta(address_);
    }

    /// @dev get the meta contract
    /// @return LTNT_Meta the meta contract currently in use
    function getMetaContract() public view returns(LTNT_Meta) {
        return _ltnt_meta;
    }

    /// @notice register an issuer address
    /// @param address_ the address of the issuer to add
    function addIssuer(address address_) public onlyOwner {
        _issuers.push(address_);
    }
    

    /// @notice determine if an address is a LW project
    /// @param address_ the address of the issuer
    /// @return bool indicating wether the address is an issuer or not
    function isIssuer(address address_) public view returns(bool){
        for(uint i = 0; i < _issuers.length; i++) {
            if(_issuers[i] == address_)
                return true;
        }
        return false;
    }


    /// @notice the ERC721 tokenURI for a given LTNT
    /// @param id_ the id of the LTNT
    /// @return json_ base64 encoded data URI containing the JSON metadata
    function tokenURI(uint id_) public view override returns(string memory json_){
        return _ltnt_meta.getJSON(id_, true);
    }


}


/// @title A title that should describe the contract/interface
/// @author troels_a
/// @dev Handles meta for this contract
contract LTNT_Meta {

    LTNT public immutable _ltnt;

    ///@dev latent fonts
    XanhMonoRegularLatin public immutable _xanh_regular;
    XanhMonoItalicLatin public immutable _xanh_italic;

    constructor(address ltnt_, address regular_, address italic_){

        _ltnt = LTNT(ltnt_);
        _xanh_regular = XanhMonoRegularLatin(regular_);
        _xanh_italic = XanhMonoItalicLatin(italic_);

    }

    /// @notice return image string for id_
    /// @param id_ the id of the LTNT to retrieve the image for
    /// @param encode_ encode output as base64 uri
    /// @return string the image string
    function getImage(uint id_, bool encode_) public view returns(string memory){

        LTNT.Issuer memory issuer_for_id_ = _ltnt.getIssuerFor(id_);
        LTNT.IssuerInfo memory issuer_info_ = LTNTIssuer(issuer_for_id_.location).issuerInfo(id_, issuer_for_id_.param);
        LTNT.IssuerInfo memory stamper_;
        LTNT.Param memory stamp_param_;
        address[] memory issuers_ = _ltnt.getIssuers();

        bytes memory stamps_svg_;
        string memory delay_;
        uint stamp_count_;
        bool has_stamp_;

        for(uint i = 0; i < issuers_.length; i++) {

            delay_ = Strings.toString(i*150);
            stamp_param_ = _ltnt.getStampParams(id_,issuers_[i]);
            stamper_ = LTNTIssuer(issuers_[i]).issuerInfo(id_, stamp_param_);
            has_stamp_ = _ltnt.hasStamp(id_, issuers_[i]);

            stamps_svg_ = abi.encodePacked(stamps_svg_, '<text class="txt italic" fill-opacity="0" y="',Strings.toString(25*i),'">',stamper_.name,' <animate attributeName="fill-opacity" values="0;',has_stamp_ ? '1' : '0.4','" dur="500ms" repeatCount="1" begin="',delay_,'ms" fill="freeze"/></text>');
            if(has_stamp_)
                ++stamp_count_;

        }

        bytes memory image_;
        image_ = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 1000" preserveAspectRatio="xMinYMin meet">',
                '<defs><style>', _xanh_regular.fontFace(), _xanh_italic.fontFace(),' .txt {font-family: "Xanh Mono"; font-size:20px; font-weight: normal; letter-spacing: 0.01em; fill: white;} .italic {font-style: italic;} .large {font-size: 55px;} .small {font-size: 12px;}</style><rect ry="30" rx="30" id="bg" height="1000" width="600" fill="black"/></defs>',
                '<use href="#bg"/>',
                '<g transform="translate(65, 980) rotate(-90)">',
                    '<text class="txt large italic">Latent Works</text>',
                '</g>',
                '<g transform="translate(537, 21) rotate(90)">',
                    '<text class="txt large italic">LTNT #',Strings.toString(id_),'</text>',
                '</g>',
                '<g transform="translate(517, 22) rotate(90)">',
                    '<text class="txt small">Issued by ',issuer_info_.name,unicode' · ', Strings.toString(stamp_count_) , stamp_count_ > 1 ? ' stamps' : ' stamp', '</text>',
                '</g>'
                '<g transform="translate(25, 25)">',
                    '<image width="300" href="', issuer_info_.image, '"/>',
                '</g>',
                '<g transform="translate(343, 41)">',
                    stamps_svg_,
                '</g>',
                '<g transform="translate(509, 980)">',
                    '<text class="txt small">latent.works</text>',
                '</g>',
            '</svg>'
        );

        if(encode_)
            image_ = abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(image_));

        return string(image_);

    }


    /// @notice return base64 encoded JSON metadata for id_
    /// @param id_ the id of the LTNT to retrieve the image for
    /// @param encode_ encode output as base64 uri
    /// @return string the image string
    function getJSON(uint id_, bool encode_) public view returns(string memory) {
        
        LTNT.Issuer memory issuer_for_id_ = _ltnt.getIssuerFor(id_);
        LTNT.IssuerInfo memory issuer_info_ = LTNTIssuer(issuer_for_id_.location).issuerInfo(id_, issuer_for_id_.param);

        bytes memory json_ = abi.encodePacked(
            '{',
                '"name":"LTNT #',Strings.toString(id_),'", ',
                '"image": "', getImage(id_, true),'", ',
                '"description": "latent.works",',
                '"attributes": [',
                    '{"trait_type": "Stamps", "value": ',Strings.toString(_ltnt.getStamps(id_).length),'},',
                    '{"trait_type": "Issuer", "value": "', issuer_info_.name, '"}',
                ']',
            '}'
        );

        if(encode_)
            json_ = abi.encodePacked('data:application/json;base64,', Base64.encode(json_));
        
        return string(json_);

    }

}


/// @title LTNTIssuer
/// @author troels_a
/// @dev LTNTIssuers implement this contract and use issuerInfo to pass info to LTNT main contract
abstract contract LTNTIssuer {
    function issuerInfo(uint id_, LTNT.Param memory param_) external virtual view returns(LTNT.IssuerInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Rando {

    function number(string memory seed, uint min, uint max) internal pure returns (uint) {
      if (max <= min) return min;
        return (uint256(keccak256(abi.encodePacked(seed))) % (max - min)) + min;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract XanhMonoRegularLatin {
    function fontFace() public pure returns(string memory){
        return "@font-face { font-family: 'Xanh Mono'; font-style: normal; font-weight: 400; font-display: swap; src: url(data:font/woff2;base64,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) format('woff2'); unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD; }";
    }
}

contract XanhMonoItalicLatin {
    function fontFace() public pure returns(string memory){
        return "@font-face { font-family: 'Xanh Mono'; font-style: italic; font-weight: 400; font-display: swap; src: url(data:font/woff2;base64,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) format('woff2'); unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD; }";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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