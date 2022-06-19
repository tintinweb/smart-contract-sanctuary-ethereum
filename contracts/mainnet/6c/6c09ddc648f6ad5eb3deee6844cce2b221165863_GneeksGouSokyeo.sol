// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.10.0;

/*
oooooooooooooooooooooooooooooOOOooOooOOOOoooOoooooooooooooooooooooooooooooo
ooooooooooooooooooooOOOooOOOo*.   oOoo°.    oOOOOoooooOoooooooooooooooooooo
ooooooooooOooooooOoO*.  *o°       ..        o*°°°OoO  *OoooOOOOOooooooooooo
ooooooooOo*oOoOOo*OO.                       *    oO*   .OoO*°..°Ooooooooooo
ooooooOo.   oO*.  oO°                       *    OO    .#o.      OooooOOOoo
oooooOo     .O    °#°         .°*o      °**oo   .#*    Oo        *oO.  .*Oo
ooooOo       O.    O°        .####°    *####O   .#    °O         °Oo    °Oo
ooooO        O°    **   .°   .OooOO°   *OooOo   °*    O.         °Oo    oOo
oooO°        o*    .o   *O   .#Oo*O°   *#oooo   .    *o     O°   *#*    OOo
oooO    *°   *o     °   °O    °.  O°    .  °o        #°    O#.   o#°   .#oo
ooO*   .#* °o#o         °O        O°       *o       o#.   °#O    OO    *#oo
ooO.   o#oO#OoO         .O        O°       °o      °#O°   .OOo*°°#o    OOoo
ooo    #OOo.  o         .O        O°       *o      *Oo*     *O####*    #ooo
oo*   °#*.    °          O    .°oO#°   .*oO#*      .OoO.      *OoO°   °#ooo
oO*   *O      ..         O   .####O°   O####°       oooO.      .OO.   *#ooo
oO°   o#.      .  .°     O   .#o°. .   oo°.         °OoOO°      °O    OOooo
oO°   *#°      .   O     o.                     °    oOoO#O°     o    #oooo
oO*   .Oo*O    .   #°    o.                     O.   °O .*O#o    o°. °#oooo
ooo    *O#O   .°   OO    *.                     Oo    .    ..   .#####Ooooo
ooO.    °*.   °o   oO°   o.      .*.      .*.   OO.              .°°*oOoooo
oooo          oo   oOo °O#. .°*o###*°*ooO###o*°*Ooo  .         ..     Ooooo
oooO°        .#O  °OooO##OOO####OOoO####OOooo###OoO**#O*.     .O.    .#oooo
ooooO°      .#OoO###oooOoooOOooooooooooooooooooooooO#OoO#Oo**o##     °#oooo
oooooO*   .*##ooOOoooooooooooooooooooooooooooooooooooooooOO###OOo*°°.oOoooo
ooooooOOOO##OoooooooooooooooooooooooooooooooooooooooooooooooooooO#####Ooooo
*/

import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract GneeksGouSokyeo is
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    PaymentSplitter,
    ReentrancyGuard
{
    using Strings for uint256;

    // allowlist
    bytes32 public merkleRoot;

    // mint phases
    enum Phase {
        FreeMint,
        PreMint,
        PublicMint
    }
    Phase public mintPhase = Phase.FreeMint;

    // metadata
    string public uriPrefix = "";
    string public uriSuffix = ".json";

    // price
    uint256 public cost = 0.1 ether;
    uint256 public maxSupply = 10000;

    // max per wallet
    uint256 public maxFreeMintAmtPerAddr = 1;
    uint256 public maxPreMintAmtPerAddr = 5;
    uint256 public maxPublicMintAmtPerAddr = 25;

    // max per tx
    uint256 public maxMintAmtPerTx = 1;

    // pause
    bool public isPaused = true;

    // allowlist
    bool public isAllowListEnabled = true;

    // reveal
    bool public isRevealed = false;

    // address to mints
    mapping(address => uint256) public freeWalletMints;
    mapping(address => uint256) public preWalletMints;
    mapping(address => uint256) public publicWalletMints;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmtPerTx,
        string memory _hiddenMetadataUriPrefix,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A(_tokenName, _tokenSymbol) PaymentSplitter(_payees, _shares) {
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmtPerTx = _maxMintAmtPerTx;
        uriPrefix = _hiddenMetadataUriPrefix;
    }

    /*
     * @dev Modifier to prevent phishing attacks.
     * Refer to https://davidkathoh.medium.com/tx-origin-vs-msg-sender-93db7f234cb9 for more details.
     */
    // modifier callerIsUser() {
    //     require(tx.origin == msg.sender, "The caller is another contract");
    //     _;
    // }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount < maxMintAmtPerTx + 1,
            "Invalid mint amount!"
        );

        if (mintPhase == Phase.FreeMint) {
            require(
                freeWalletMints[_msgSender()] + _mintAmount <
                    maxFreeMintAmtPerAddr + 1,
                "User free mint limit exceeded!"
            );
        } else if (mintPhase == Phase.PreMint) {
            require(
                preWalletMints[_msgSender()] + _mintAmount <
                    maxPreMintAmtPerAddr + 1,
                "User premint limit exceeded!"
            );
        } else if (mintPhase == Phase.PublicMint) {
            require(
                publicWalletMints[_msgSender()] + _mintAmount <
                    maxPublicMintAmtPerAddr + 1,
                "User mint limit exceeded!"
            );
        }

        require(
            totalSupply() + _mintAmount < maxSupply + 1,
            "Max supply exceeded!"
        );

        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function isAllowListed(address user, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
        nonReentrant
    {
        require(!isPaused, "The contract is paused!");

        // check if address is on allowlist if enabled
        // if (isAllowListEnabled) {
        //     bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        //     require(
        //         MerkleProof.verify(_merkleProof, merkleRoot, leaf),
        //         "Only allowlist users can mint!"
        //     );
        // }
        if (isAllowListEnabled) {
            require(
                isAllowListed(_msgSender(), _merkleProof),
                "Only allowlist users can mint!"
            );
        }

        // TODO: add check to make sure a valid mint phase exists?
        if (mintPhase == Phase.FreeMint) {
            freeWalletMints[_msgSender()] += _mintAmount;
        } else if (mintPhase == Phase.PreMint) {
            preWalletMints[_msgSender()] += _mintAmount;
        } else if (mintPhase == Phase.PublicMint) {
            publicWalletMints[_msgSender()] += _mintAmount;
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        external
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount < maxSupply + 1,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setIsRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmtPerTx(uint256 _maxMintAmtPerTx) external onlyOwner {
        maxMintAmtPerTx = _maxMintAmtPerTx;
    }

    function setMaxFreeMintAmountPerAddress(uint256 _maxFreeMintAmtPerAddr)
        external
        onlyOwner
    {
        maxFreeMintAmtPerAddr = _maxFreeMintAmtPerAddr;
    }

    function setMaxPreMintAmountPerAddress(uint256 _maxPreMintAmtPerAddr)
        external
        onlyOwner
    {
        maxPreMintAmtPerAddr = _maxPreMintAmtPerAddr;
    }

    function setMaxPublicMintAmtPerAddress(uint256 _maxPublicMintAmtPerAddr)
        external
        onlyOwner
    {
        maxPublicMintAmtPerAddr = _maxPublicMintAmtPerAddr;
    }

    // TODO: rename?
    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    // TODO: rename?
    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMintPhase(Phase _phase) external onlyOwner {
        mintPhase = _phase;
    }

    function setIsPaused(bool _state) external onlyOwner {
        isPaused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setIsAllowListEnabled(bool _state) external onlyOwner {
        isAllowListEnabled = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}