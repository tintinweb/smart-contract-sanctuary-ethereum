// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// We will add the Interfaces here
/**
    Interface do FakeMarketPlace
*/
interface IFakeNFTMarketPlace {
    // getPrice() retorna o preco de uma nft do marketplace
    // retorna o preco em wei de um nft
    function getPrice() external view returns(uint256);

    //available() retorna se o _tokenId foi ou nao comprado
    function available(uint256 _tokenId) external view returns (bool);

    //purchase() compra o nft no marketplace
    //_tokenId o fake tokenId
    function purchase(uint256 _tokenId) external payable; 
}
/**
    Interface CryptoDevsNFT contendo apenas duas funcoes que nos estamos interessados
*/
interface ICryptoDevsNFT {
    //balanceOf - retorna o numero de nfts pertencentes a um dado endereço
    //owner - endereco para retornar o dono nft
    function balanceOf(address owner) external view returns (uint256);

    //tokenOfOwnerByIndex retorna um tokenId de um dado indice
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view 
        returns(uint256);
}

/**
    Functionalities we need in the DAO contract:
    i)   Store created proposals in contract state
    ii)  Allow holders of the CryptoDevs NFT to create new proposals
    iii) Allow holders of the CryptoDevs NFT to vote on proposals,
        given they haven't already voted, and that the proposal hasn't passed
        it's deadline yet
    iv) Allow holders of the CryptoDevs NFT to execute a proposal after
        it's deadline has been exceeded, triggering an NFT purchase in case it passed
 */

contract CryptoDevsDAO is Ownable {
    //struct Proposal contem todas as informacoes relevantes
    struct Proposal {
        //nftTokenId - o tokenId do nft comprado no markeplace
        uint256 nftTokenId;
        //deadline - unix timestamp marcando o tempo que a proposta esta ativa
        uint256 deadline;
        //yayVotes - numeros de yay votes nesta proposta
        uint256 yayVotes;
        //nayVotes - numeros de nay votes nesta prposta
        uint256 nayVotes;
        //executed - se a proposta foi ou nao executada. Nao pode ser executada apos deadline
        bool executed;
        //voters - mapping os donos de nfts
        mapping(uint256 => bool) voters;
    }

    //Cria a mapping de ID para Proposal
    mapping(uint256 => Proposal) public proposals;
    //numero de propostas que foram criadas
    uint256 public numProposals;

    //iniciando as variaveis dos contratos
    IFakeNFTMarketPlace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    //Cria um constructor pagavel e inicializa o contrato
    //instancia o Fakemarketplace
    constructor(address _nftMarketPlace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketPlace(_nftMarketPlace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    //cria um modifier para evitar duplicidade de codigo
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    /// @dev createProposal  permite que o dono da nft crie uma proposta para DAO
    /// @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace 
    /// @return Returns the proposal index for the newly created proposal
    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns(uint256)
    {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        //configura a data limite da proposta como tempo atual + 5 minutos
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    //modifier permite apneas ser chamada se a data limite nao foi excedida
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEED"
        );
        _;
    }

    //criar enum para colocar os yay nay
    // YAY = 0
    // NAY = 1
    enum Vote {
        YAY,
        NAY  
    }

    //voteOnProposal permite ao dono de uma nft CryptoDevsNFt votar na proposta aberta
    // param proposalIndex - o indice da proposta em um array
    // param vote - o tipo de voto que eles 
    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external 
        nftHolderOnly
        activeProposalOnly(proposalIndex)
        {
            Proposal storage proposal = proposals[proposalIndex];

            uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
            uint256 numVotes = 0;

            //Calcula quantos nfts pertencem por votos
            //que nao foram usados na votacao por proposta
            for(uint256 i = 0; i < voterNFTBalance; i++) {
                uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
                if(proposal.voters[tokenId] == false) {
                    numVotes++;
                    proposal.voters[tokenId] = true;
                }
            }
            
            require(numVotes > 0, "ALREADY_VOTED"); 

            if(vote == Vote.YAY) {
                proposal.yayVotes += numVotes;
            } else {
                proposal.nayVotes += numVotes;
            }
        }
    
    //cria um modifier que permite a execucao de uma funcao
    // de uma determinada prpoposta que ja tenha seu tempo excedido mas nao executada
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEED"
        );
        require(proposals[proposalIndex].executed == false,
        "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    //executeProposal - executa proposta
    //param proposalIndex - o indice da proposta a ser executada 
    function executeProposal(uint256 proposalIndex)
        external 
        nftHolderOnly
        inactiveProposalOnly(proposalIndex) 
    {
        Proposal storage proposal = proposals[proposalIndex];

        //se a proposta tem mais sim do que nao ela e executada
        if(proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    //permite que o dono do contrato saque o valor do contrato
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //essas funcoes permitem adicionar tokens no contrato 
    receive() external payable {}
    fallback() external payable {}
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