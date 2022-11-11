// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// This is an NFT for Warrior NFT https://twitter.com/WaroftheWand

/*
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^::::::::^:::::::::^::::::::^^^^^^::::::^^^^::::::^^:::::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^:^555!^^^:^^55555^^:^^^!555^:^^^^^^JPPJ^^^^^^JPPJ^^^:7PP5^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^:[email protected]!5BB5~P#J?!YP#[email protected]~:^^^:7&J!?5&7::7&J!?5&7^#P!?J#5:::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^:[email protected] :^7YG&@7~^[email protected]&GY7^: [email protected]~:::::7B55GGG7::7GP5PGB7^PP5PPBY:!??!::^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^:^JY5~.  .?5BBPBB5?.  .~5YJ:!55Y^::[email protected]!::[email protected]::^Y55#&^~5YY555!:^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^:^[email protected]#G~:  .7???7.  :~G#@BGBP?JYBY:[email protected]??JPP^[email protected]~&G^YGYJ7G#^[email protected]@?:^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^:^BG?JYBP!!! ^Y^ !!!PBYJ?G##GJ5P#P!P#@G77?#G7??5G&[email protected]?!J###@G~^:^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^:!PYYGBB&&77?77&&BBGYYP!::!P&@7JBJ7#G??J#P!?J5PBJ!JYGPPB57PBPJ::^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^:::7YJ5B&@[email protected]&B5JY7::::::7YGPJYY7!~~!7!^!7!!~~!5Y!!7J5#5?^:^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^:::^[email protected]@B!^:::^^^^^^::!Y&Y7:~JJ?^!YJ?:[email protected]?::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^::[email protected]@P::^^^^^^^^^^::[email protected]~~~!!!!777!!!!~:[email protected]?:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^:[email protected]!7GB#@G:^^^^^^^^^^^::[email protected][email protected]?::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^:[email protected]#[email protected]:^^^^^^^^^^:^PP5B#[email protected]^:^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^:~!&#[email protected]:^^^^^^^^^^:[email protected]@BG57~~~7J5GBBJ7JJY7!???B#7~::::^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^:^&&B##@G:^^^^^^^^^^:^&#Y#@ <O> ^^ <O> ^^~?JY??YY???GP?J?:::::::^:::^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^:~&&#[email protected]::^^^^^^^^:?5GPYPG5Y7~~!!!?J:::^~Y5BBB5YYJ?7JPPP555555?:^^^:::^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^:~&&[email protected]~^::^^^^^::[email protected]##BGY^!7??**[email protected]@&BG55Y??J??Y555YJYGGGGY~^::^^^^^^^^^
^^^^^^^^^^^^^^^^^^:^@&G#&@&GJ!^:^^^:[email protected]&BJ****?JY?JJ5PB#@[email protected]#GP5?JY?77JJ??J?77JBJ!::^^^^^^^^
^^^^^^^^^^^^^^^^^:[email protected]@^:^^::[email protected]?:^[email protected][email protected]&GJ7?YYY77JGGG5P#J7GGP!^5PB5YYJ???J5GGGJ??PGY7:::^^^^^
^^^^^^^^^^^^^^^^^:[email protected]^:~~!&G~J5PJ::^[email protected][email protected]@[email protected][email protected]~^[email protected]~~^:~JG#Y5#5J?J5&@#GYJJPPP!:^^^^^
^^^^^^^^^^^^^^^^^:[email protected]?JJYP5Y??&G~^^@B^!7G#@?::[email protected][email protected]#PJ!.:~&#J?7~!7G#55P#&5Y7G&JYBP5JYYGB^:^^^
^^^^^^^^^^^^^^^^^:[email protected]~^^[email protected]!.!G5Y??J77Y5G7:::^[email protected]#[email protected]#JG&@#GYJGP?5PGPJG#?!:^^
^^^^^^^^^^^^^^^^^:[email protected]@@GYJ7^[email protected]#@P?~^[email protected][email protected]:^!JPBBB#[email protected]#[email protected]::^
^^^^^^^^^^^^^^^^^^::[email protected]#[email protected]#YYY5Y77?#[email protected]@@[email protected][email protected]~7?JP&[email protected]@@5J?!~:[email protected]?#[email protected]~~?G#PPB7:
^^^^^^^^^^^^^^^^^^^::[email protected]&#@&[email protected]#YPG&B5#&?!^5BYJ?YP#[email protected]@#[email protected]#[email protected]?:BB555#5.5#PG&7:
^^^^^^^^^^^^^^^^^^^^:[email protected]@G:JP5PBP5B##&@5YJ#@B5!~~&#J#@77JY5GGP#@5P#5J&&#[email protected]?^GGP!::[email protected]@G:^^PJ:^^
^^^^^^^^^^^^^^^^^^^^:[email protected]@G::^JYJG#BGJ#@[email protected]&[email protected]&BBGGPPB#@[email protected]#@@&#[email protected]?:J7::^:[email protected]@G::::::^^
^^^^^^^^^^^^^^^^^^^^:[email protected][email protected]:^::::~77~:[email protected]@[email protected]#YB&?JP##[email protected]^!7#BJ#@[email protected][email protected]^::^^^:~!PB7~:^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]#[email protected]:^^^^^:::::[email protected]#&PPG#&GGGGGG#@7:GGPGG7J#Y7!7JB&!:^^^^::^~::^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]@G:^^^^^^^^^^:^&@@?..^J77Y55?7~!J~..~5YJ:[email protected]?^@G^7?:[email protected]!:^^^^^^::^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]@G:^^^^^^^^^^:~&B7~:~7P7~....:~7P7~::[email protected]~~?5P?7~PB^:[email protected]!:^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected][email protected]:^^^^^^^^^^:^@G [email protected][email protected]!~:^!#5.5#~!YJJ77JG#!:^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]#[email protected]:^^^^^^^^^:!?PJ:[email protected]&P&@J77~^P5?~^PGBGGGGG7^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]@G:^^^^^^^^::[email protected]@&[email protected]#[email protected]?::!YYYY?:::^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]@G:^^^^^^^:7BJ!?J5B#PG#&&^::::[email protected]&#Y?!!!7PG^::::::^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected][email protected]:^^^^^^::[email protected]?PPPB##&@J^^^^^::^~G&[email protected]!~5B7~:^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]@G:^^^^^:^[email protected]#BP!:^^^^^^::[email protected]::^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]@G:^^^^^:[email protected]^[email protected]:^^^^^^^^^:^&#J#@5P#5??JP!:^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:[email protected]?^@G:^^^^^:^!J#J!7?YGB&P~^:^^^^^^^^:^!JB&@[email protected]?:^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^:7B?!GY:^^^^^^^:[email protected][email protected]?:^^^^^^^^^^:^^[email protected]&[email protected]?:^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^::[email protected]^:^^^^^^^^^::[email protected]#@J^[email protected]?:^^^^^^^^^^^::?5#BP&@##@?:^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^:!7^:^^^^^^^^:::[email protected][email protected]?~:^^^^^^^^^^^^^::[email protected]?^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^:::^^^^^::::!!!G&[email protected]:^^^^^^^^^^^^^^^^[email protected]!7JP##^:^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::~JJJ5PPJ??7~~~BG?~:^^^^^^^^^^^^^:^@B??????5PJ7::^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^[email protected]?:^^^^^^^^^^^^:J5J?~~~~~~^~GG5!:^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^:[email protected]#?JJYYYYYYYYYY#G7~:^^^^^^^^^^^^:[email protected]@?:^^^^^^^^^^^^^^^^^^^^
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./PaymentSplitter.sol";
import {DefaultOperatorFilterer721, OperatorFilterer721} from "./DefaultOperatorFilterer721.sol";

interface Staker {
    function userStakeBalance(address user) external view returns (uint256);
    function userBurntBalance(address user) external view returns (uint256);
    function stakeList(address user) external view returns (uint16[] memory);
    function burntList(address user) external view returns (uint16[] memory ids);
}

contract Warrior is
    ERC721A,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    DefaultOperatorFilterer721,
    ERC2981
{

    string private constant _name = "Warriors of the Wand";
    string private constant _symbol = "WOTW";
    string public baseURI = "ipfs://QmNqEnxCjPidStahDS4VPdLifceHEX5YBCqN9kZHFSYPP5/";
    uint256 public cost = 0.025 ether;
    uint16 public maxSupply = 7777;
    uint16 public freeSupply = 1111;
    uint16 public paidSupply = 2222;
    uint16 public freeMinted;
    uint16 public paidMinted;
    uint16[7777] private claimed;
    bool public freezeURI = false;
    bool public freezeSupply = false;
	bool public paused = true;
    mapping(uint256 => bool) public tokenToIsStaked;
	mapping(address => uint16) public minted;

    address[] private firstPayees = [0x9FcFD77494a0696618Fab4568ff11aCB0F0e5d9C, 0xa4D89eb5388613A9BF7ED0eaFf5fD2c05a4B34e3];
    uint16[] private firstShares = [50, 50];

    Staker public staking = Staker(0xC8BDDeFfD870f2a66409D888F4D1517b78Bd8312);

    constructor() ERC721A(_name, _symbol) PaymentSplitter(firstPayees, firstShares) payable {
        _setDefaultRoyalty(address(this), 750);
    }

    // to support royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // returns how many can be minted for free 
    function unclaimed(address user) public view returns (uint16) {
        uint16 available;
        uint256 stakeBalance = staking.userStakeBalance(user);
        uint256 burnBalance = staking.userBurntBalance(user);
        uint16[] memory ids;
        uint16 i;

        unchecked {
            if (stakeBalance > 0) {
                ids = staking.stakeList(user);

                for (i = 0; i < stakeBalance; i++) {
                    available += 1 - claimed[ids[i]];
                }
            }

            if (burnBalance > 0) {
                ids = staking.burntList(user);

                for (i = 0; i < burnBalance; i++) {
                    available += 2 - claimed[ids[i]];
                }
            }
        
            if (available > freeSupply - freeMinted) {
                available = freeSupply - freeMinted;
            }
        }

        return available;
    }

    // @dev public minting
	function mint(uint16 mintAmount) external payable nonReentrant {
        uint16 available = unclaimed(msg.sender);
        uint16[] memory ids;
        uint16 i;
        uint256 stakeBalance;
        uint256 burnBalance;

        require(Address.isContract(msg.sender) == false, "Warrior: no contracts");
        require(paused == false || msg.sender == owner(), "Warrior: Minting not started yet");
        require(totalSupply() + mintAmount <= maxSupply, "Warrior: Can't mint more than max supply");

        unchecked {
            if (msg.sender == owner() || msg.sender == 0xa4D89eb5388613A9BF7ED0eaFf5fD2c05a4B34e3) {
                //no cost to owner
                paidMinted += mintAmount;

            } else if (available > 0) {
                if (mintAmount > available) {
                    mintAmount = available;
                }
                uint16 claiming = mintAmount;

                //1 free mint for each id staked
                stakeBalance = staking.userStakeBalance(msg.sender);
                if (stakeBalance > 0) {
                    ids = staking.stakeList(msg.sender);

                    for (i = 0; i < stakeBalance; i++) {
                        if (claiming > 0 && claimed[ids[i]] == 0) {
                            claimed[ids[i]] = 1;
                            claiming -= 1;
                        }
                    }
                }

                //2 free mint for each id burnt
                burnBalance = staking.userBurntBalance(msg.sender);
                if (burnBalance > 0) {
                    ids = staking.burntList(msg.sender);

                    for (i = 0; i < burnBalance; i++) {
                        if (claiming > 1 && claimed[ids[i]] == 0) {
                            claimed[ids[i]] = 2;
                            claiming -= 2;
                        } else if (claiming > 0 && claimed[ids[i]] == 1) {
                            claimed[ids[i]] = 2;
                            claiming -= 1;
                        }
                    }
                }

                freeMinted += mintAmount;

            } else if (paidMinted < paidSupply) {
                require(paidMinted + mintAmount <= paidSupply, "Warrior: Cannot mint this many");
                require(msg.value >= cost * mintAmount, "Warrior: You must pay for the nft");

                paidMinted += mintAmount;

            } else {
                require(false, "Warrior: none available to mint");
            }

            minted[msg.sender] += mintAmount;
        }

        _safeMint(msg.sender, mintAmount);
	}

    //@dev prevent transfer or burn of staked id
    function _beforeTokenTransfers(address /*from*/, address /*to*/, uint256 startTokenId, uint256 /*quantity*/) internal virtual override {
        require(tokenToIsStaked[startTokenId] == false, "Warrior, cannot transfer - currently locked");
    }

    /**
     *  @dev returns whether a token is currently staked
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return tokenToIsStaked[tokenId];
    }

    /**
     *  @dev marks a token as staked, calling this function
     *  you disable the ability to transfer the token.
     */
    function stake(uint256 tokenId) external nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Warrior: caller is not the owner");
        tokenToIsStaked[tokenId] = true;
    }

    /**
     *  @dev marks a token as unstaked. By calling this function
     *  you re-enable the ability to transfer the token.
     */
    function unstake(uint256 tokenId) external nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Warrior: caller is not the owner");
        tokenToIsStaked[tokenId] = false;
    }

    // @dev set cost of minting
	function setCost(uint256 _newCost) external onlyOwner {
    	cost = _newCost;
	}
		
    // @dev unpause main minting stage
	function setPaused(bool _status) external onlyOwner {
    	paused = _status;
	}
	
    // @dev set how many can be minted by paid minters
	function setPaidSupply(uint16 _new) external onlyOwner {
        require(_new >= paidMinted, "Warrior: too low");
    	paidSupply = _new;
	}

    // @dev set how many can be minted for free from stakers and burners
	function setFreeSupply(uint16 _new) external onlyOwner {
        require(_new >= freeMinted, "Warrior: too low");
    	freeSupply = _new;
	}

    // @dev Set the base url path to the metadata
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(freezeURI == false, "Warrior: uri is frozen");
        baseURI = _baseTokenURI;
    }

    // @dev freeze the URI
    function setFreezeURI() external onlyOwner {
        freezeURI = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev Add payee for payment splitter
    function FreezeSupply() external onlyOwner {
        freezeSupply = true;
    }

    //reduce max supply if needed
    function setMaxSupply(uint16 newMax) external onlyOwner {
        require(freezeSupply == false, "Warrior: Max supply is frozen");
        require(newMax < maxSupply, "Warrior: New maximum must be less than existing maximum");
        maxSupply = newMax;
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // @dev Add payee for payment splitter
    function addPayee(address account, uint16 shares_) external onlyOwner {
        _addPayee(account, shares_);
    }

    // @dev Set the number of shares for payment splitter
    function setShares(address account, uint16 shares_) external onlyOwner {
        _setShares(account, shares_);
    }

    // @dev add tokens that are used by payment splitter
    function addToken(address account) external onlyOwner {
        _addToken(account);
    }

    // @dev release payments to one payee
    function release(address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Warrior: no contracts");
        _release(account);
    }

    // @dev release ERC20 tokens due to a payee
    function releaseToken(IERC20 token, address payable account) external nonReentrant {
        require(Address.isContract(account) == false, "Warrior: no contracts");
        _releaseToken(token, account);
    }

    // @dev anyone can run withdraw which will send all payments
    function withdraw() external nonReentrant {
        _withdraw();
    }

    function setUseFilter(bool Use) external onlyOwner {
        setUse(Use);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}