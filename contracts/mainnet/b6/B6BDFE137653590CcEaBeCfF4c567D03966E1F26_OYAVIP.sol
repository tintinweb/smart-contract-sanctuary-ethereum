// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OYAVIP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//    Get lifetime access to all OYA locations.                                                       //
//    You can reserve the entire place for yourself and get a host of perks                           //
//    and airdrops to enhance your stay and transform your life.                                      //
//    OYA is a global brand that will always give you a home away from home                           //
//    and access to transformative events and people year after year.                                 //
//                                                                                                    //
//    Downpayment of $3k USD (translate to ETH) now and                                               //
//    total payment of $125k USD (translate to ETH) for the full VIP experience.                      //
//                                                                                                    //
//    OYA will be in touch for the rest of the payment and next steps.                                //
//                                                                                                    //
//    There will be 10 VIP NFTs ever made.                                                            //
//                                                                                                    //
//                                                                                                    //
//    <3 <3 <3                                                                                        //
//                                                                                                    //
//    OYA NFT Terms of Use                                                                            //
//    Last revised: 20 th October, 2022                                                               //
//    These Terms of Use (“Terms”) apply to your purchase, sale and display of OYA non-               //
//    fungible tokens (“OYA NFTs”). Some purchases of OYA NFTs may include special                    //
//    [experience opportunities]. Please view terms regarding such [experiences here]                 //
//    (“Experience Terms”). To the extent there is a conflict between these Terms and the             //
//    Experience Terms, these Terms control.                                                          //
//    These Terms are entered into between you and OYA Club LLC (“Company,” “we,” or                  //
//    “us”). These Terms expressly incorporate any other documents referenced herein (such            //
//    as our Privacy Policy) and govern your access to and use of this site www.OYA.io (the           //
//    “Site”), as well as all content, functionality, and services offered on or through the Site,    //
//    including the OYA NFTs.                                                                         //
//    1. Reviewing and Accepting These Terms                                                          //
//    Please read these Terms carefully, as they set out your rights and responsibilities             //
//    when you use this Site to buy OYA NFTs (the “Services”). When each OYA NFT is                   //
//    sold for the first time, the agreement for sale is between the Company and the                  //
//    initial purchaser. If the initial purchaser decides to sell the OYA NFT through this            //
//    Site, then this Site serves only as a platform that facilitates transactions between            //
//    a buyer and a seller and the Company is not a party to any agreement between                    //
//    such buyer and seller of OYA NFTs or between any other users.                                   //
//    All OYA NFTs are stored on and accessible through the Ethereum blockchain. As                   //
//    such, the Company does not maintain the OYA NFTs on this Site and, aside from                   //
//    transferring control of the OYA NFT to the initial purchaser of the OYA NFT, the                //
//    Company has no control over the transfer, storage, ownership or maintenance of                  //
//    the OYA NFT.                                                                                    //
//    When you connect your cryptocurrency wallet to the Site using a trusted service                 //
//    provide such as MetaMask or Wallet Connect, you accept and agree to be bound                    //
//    and abide by these Terms and all of the terms incorporated herein by reference.                 //
//    By agreeing to these Terms, you hereby certify that you are at least 18 years of                //
//    age. If you do not agree to these Terms, you must not access or use the Site.                   //
//    Please note that Section 17 contains an arbitration clause and class action                     //
//    waiver. By agreeing to these Terms, you agree to resolve all disputes through                   //
//    binding individual arbitration, which means that you waive any right to have the                //
//    dispute decided by a judge or jury, and you waive any right to participate in                   //
//    collective action, whether that be a class action, class arbitration, or                        //
//    representative action. You have the ability to opt-out of this arbitration clause by            //
//    sending us notice of your intent to do so within thirty (30) days of your initial               //
//    agreement to these Terms.                                                                       //
//                                                                                                    //
//    We reserve the right to change or modify these Terms at any time and in our sole                //
//    discretion. You agree and understand that by accessing or using the Site                        //
//    following any change to these Terms, you are agreeing to the revised Terms and                  //
//    all of the terms incorporated therein by reference.                                             //
//    Review the Terms each time you access the Site to ensure that you understand                    //
//    how the Terms apply to your activities on the Site.                                             //
//    2. Linking Your Cryptocurrency Wallet                                                           //
//    When you link your cryptocurrency wallet, you understand and agree that you are                 //
//    solely responsible for maintaining the security of your wallet and your control                 //
//    over any wallet-related authentication credentials, private or public                           //
//    cryptocurrency keys, non-fungible tokens or cryptocurrencies that are stored in or              //
//    are accessible through your wallet. Any unauthorized access to your                             //
//    cryptocurrency wallet by third parties could result in the loss or theft of OYA                 //
//    NFTs and/or funds held in your wallet and any associated wallets, including any                 //
//    linked financial information such as bank account(s) or credit card(s). We are not              //
//    responsible for managing and maintaining the security of your cryptocurrency                    //
//    wallet nor for any unauthorized access to or use of your cryptocurrency wallet. If              //
//    you notice any unauthorized or suspicious activity in your cryptocurrency wallet                //
//    that seems to be related to this Site, please notify us immediately.                            //
//    3. Ownership                                                                                    //
//    Unless otherwise indicated in writing by us, the Site, all content, and all other               //
//    materials contained therein, including, without limitation, our logos, and all                  //
//    designs, text, graphics, pictures, information, data, software, sound files, other              //
//    files, and the selection and arrangement thereof (collectively, “Site Content”) are             //
//    the proprietary property of OYA or our affiliates, licensors, or users, as applicable.          //
//    The OYA logo and any OYA product or service names, logos, or slogans that may                   //
//    appear on the Site or elsewhere are trademarks of OYA or our affiliates, and may                //
//    not be copied, imitated or used, in whole or in part, without our prior written                 //
//    permission.                                                                                     //
//    You may not use any Site Content or link to the Site without our prior written                  //
//    permission. You may not use framing techniques to enclose any Site Content                      //
//    without our express written consent. In addition, the look and feel of the Site                 //
//    Content, including without limitation, all page headers, custom graphics, button                //
//    icons, and scripts constitute the service mark, trademark, or trade dress of OYA                //
//    and may not be copied, imitated, or used, in whole or in part, without our prior                //
//    written permission.                                                                             //
//    4. Terms of Sale                                                                                //
//                                                                                                    //
//    We are offering for sale three types of digital collectibles (each a “Membership                //
//    NFT”) on or about December 1 st , 2022: a “local membership” NFT (“Local NFT”),                 //
//    Global Membership NFT (“Global Membership”), and a Corporate Membership                         //
//    NFT(“Corporate NFT”). The purchase of each NFT is a transaction in goods and                    //
//    not a promise to provide, or a guarantee of receipt of, future services from OYA,               //
//    although OYA will make reasonable efforts to ensure that the community comes                    //
//    into existence which allows you to unlock expanded functionality associated with                //
//    the Membership NFTs. Right to membership in the Oya Leisure club will be                        //
//    subject to club rules, the terms of which will be determined by OYA, and may be                 //
//    changed from time to time.                                                                      //
//    By placing an order on the Site, you agree that you are submitting a binding offer              //
//    to purchase a OYA NFT or other Service. If you are the initial purchaser of a OYA               //
//    NFT or you are purchasing a Service, then all amounts due are to be paid to OYA                 //
//    Club LLC. If you are not the initial purchaser of a OYA NFT, then amounts may be                //
//    paid to the-then holder of the OYA NFT. You also acknowledge and agree that                     //
//    Company receives 10% of every subsequent sale of a OYA NFT (“Royalty”). For                     //
//    example, if you are the initial purchaser, and you sell a OYA NFT for $100 to a                 //
//    subsequent purchaser, $10 will automatically be transferred to Company and you                  //
//    will receive $90. Company has the right collect Royalties for OYA NFT sales in                  //
//    perpetuity and may use those funds in any manner Company sees fit.                              //
//    Notwithstanding the foregoing, the Company has committed to donate 10% of all                   //
//    Royalties Company receives annually to a charity of Company’s choosing. The                     //
//    Company may make such payment at such time as it desires.                                       //
//    As such, if you sell a OYA NFT on a third-party NFT marketplace, you agree to                   //
//    include a statement substantially similar to the following in the description of the            //
//    NFT:                                                                                            //
//    “10% Royalty Applies. See OYA Terms for details.”                                               //
//    In addition, when you buy or sell a OYA NFT on this Site, you agree to pay all                  //
//    applicable fees associated with the transaction and you authorize Company to                    //
//    automatically charge and collect such fees from your payment. We will always                    //
//    display a breakdown of any transaction or other fees prior to your purchase or                  //
//    sale of a OYA NFT.                                                                              //
//    No refunds are permitted except with respect to any statutory warranties or                     //
//    guaranties that cannot be excluded or limited by law.                                           //
//    You understand and agree that the sale of Membership NFTs grants you no                         //
//    rights and carries with it no guarantee of future performance of any kind by Oya,               //
//    LLC. You are not entitled, as a holder of any Membership NFT, to vote or receive                //
//    dividends or profits or be deemed the holder of shares of OYA, LLC. or any other                //
//    person by virtue of your ownership of a Membership NFT, nor will anything                       //
//    contained herein be construed to construe on you any of the rights of a                         //
//                                                                                                    //
//    shareholder, partner, joint venturer, etc. or any right to vote for the election of             //
//    directors or upon any matter submitted to shareholders at any meeting thereof,                  //
//    or to give or withhold consent to any corporate action or to receive notice of                  //
//    meetings, or to receive subscription rights to purchase such shares/units of OYA,               //
//    LLC. You agree that the functionality and operation of the OYA resort established               //
//    by Oya LLC will be determined by OYA LLC in its sole and absolute discretion.                   //
//    5. Intellectual Property                                                                        //
//    Other than Site Content, all other trademarks, product names, and logos on the                  //
//    Site are the property of their respective owners and may not be copied, imitated,               //
//    or used, in whole or in part, without the permission of the applicable trademark                //
//    holder. Without limiting the foregoing, if you believe that third-party material                //
//    hosted on the Site infringes your copyright or trademark rights, please file a                  //
//    notice of infringement by contacting the Designated Copyright Agent listed                      //
//    below.                                                                                          //
//    Your notice must contain the following information as required by the Digital                   //
//    Millennium Copyright Act (17 U.S.C. §512) (“DMCA”):                                             //
//    o The full name and a physical or electronic signature of the person                            //
//    authorized to act on behalf of the copyright owner;                                             //
//    o Identification of the copyrighted work claimed to have been infringed. If                     //
//    multiple copyrighted works are covered by your notice, you may provide a                        //
//    representative list of the copyrighted works that you claim have been                           //
//    infringed;                                                                                      //
//    o Reasonably sufficient detail to enable us to identify and locate the                          //
//    copyrighted work that is claimed to be infringing (e.g. a link to the page on                   //
//    the Site that contains the material);                                                           //
//    o A mailing address, telephone number, and email address where we can                           //
//    contact you;                                                                                    //
//    o A statement that you have a good faith belief that the disputed use of the                    //
//    copyrighted work is not authorized by the copyright owner, its agent, or the                    //
//    law; and                                                                                        //
//    o A statement made by you, under penalty of perjury, that the information in                    //
//    the notice is accurate and that you are the copyright owner or are                              //
//    authorized to act on behalf of the copyright owner.                                             //
//    Please submit your notice to the Designated Agent below:                                        //
//    OYA Club LLC                                                                                    //
//    Legal Department                                                                                //
//    450 7th ave suite 1408 ny ny 10123                                                              //
//                                                                                                    //
//    Email: [email protected]                                                                              //
//    Once you provide us with an adequate notice as described above, we will                         //
//    respond expeditiously and take whatever action, in our sole discretion, that is                 //
//    deemed appropriate including removal of the disputed copyrighted work from the                  //
//    Site.                                                                                           //
//    Counter-Notice:                                                                                 //
//    If you believe that a DMCA notice of copyright infringement has been improperly                 //
//    submitted against you, you may submit a counter-notice to the Designated Agent                  //
//    with the following information required by the DMCA:                                            //
//    o Your physical or electronic signature;                                                        //
//    o Identification of the copyrighted work that has been removed or to which                      //
//    access has been disabled including a link to the page on the Site that                          //
//    contained the material before it was removed or disabled;                                       //
//    o A statement under penalty of perjury that you have a good faith belief that                   //
//    the copyrighted work was removed or disabled as a result of mistake or                          //
//    misidentification;                                                                              //
//    o Your name, address, e-mail address, and telephone number; and                                 //
//    o A statement that you (i) consent to the jurisdiction of the Federal District                  //
//    Court in the judicial district where your address is located if the address is                  //
//    in the United States, or the United District Court for the Southern District of                 //
//    New York (Manhattan) if your address is located outside of the United                           //
//    States, and (ii) accept service of process from the person who provided                         //
//    the DMCA notice of the alleged copyright infringement.                                          //
//    Please submit your notice to the Designated Agent below:                                        //
//    OYA Club LLC                                                                                    //
//    Legal Department                                                                                //
//    450 7th ave suite 1408 ny ny 10123                                                              //
//    Email: [email protected]                                                                              //
//    In the event that the Company receives a counter-notice in compliance with the                  //
//    above requirements, we will provide the person who submitted the DMCA                           //
//    copyright infringement notice with a copy of the counter-notice, informing them                 //
//    that the Company will replace the removed material in 10 business days from the                 //
//    date of the counter-notice unless the Company first receives notice from the                    //
//    person who submitted the DMCA copyright infringement notice that they have                      //
//    filed an action seeking a court order to restrain the allegedly infringing activity.            //
//                                                                                                    //
//    PLEASE NOTE THAT OYA INTENDS TO COMPLY WITH ALL PROVISIONS OF THE                               //
//    DIGITAL MILLENNIUM COPYRIGHT ACT, BUT WILL NOT UNILATERALLY TAKE                                //
//    RESPONSIBILITY FOR POLICING AND REMOVING MATERIAL THOUGHT TO BE                                 //
//    INFRINGING.                                                                                     //
//    We hereby grant you a limited, non-exclusive, non-transferable, revocable license               //
//    to access and use the Site Content. In return, you agree not to engage, or assist,              //
//    in any activity that violates any law, statute, ordinance, regulation, or sanctions             //
//    program, including but not limited to the U.S. Department of Treasury’s Office of               //
//    Foreign Assets Control (“OFAC”), or that involves proceeds of any unlawful                      //
//    activity; not to engage in any other activity or behavior that poses a threat to OYA            //
//    Club LLC, (e.g., by distributing a virus or other harmful code, or through                      //
//    unauthorized access to the Site or other users’ cryptocurrency wallets and not to               //
//    interfere with other users’ access to or use of the Services.                                   //
//    You also agree not to (1) distribute, publish, broadcast, reproduce, copy,                      //
//    retransmit, or publicly display any Site Content; (2) modify or create derivative               //
//    works from the Site Content, or any portion thereof; (3) use any data mining,                   //
//    robots, or similar data gathering or extraction methods on the Site Content; (4)                //
//    download any portion of the Site Content, other than for purposes of page                       //
//    caching, except as expressly permitted by us.                                                   //
//    With respect to the OYA NFTs, each purchaser of a OYA NFT is granted an                         //
//    exclusive, limited license to such OYA NFT and its content to access, use, or                   //
//    store such OYA NFT and its content solely for their personal, non-commercial                    //
//    purposes. OYA NFTs are a limited-edition digital creation based upon content                    //
//    that may be trademarked and/or copyrighted by Company. Unless otherwise                         //
//    specified, your purchase of a OYA NFT does not give you the right to publicly                   //
//    display, perform, distribute, sell or otherwise reproduce the OYA NFT or its                    //
//    content for any commercial purpose.                                                             //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OYAVIP is ERC721Creator {
    constructor() ERC721Creator("OYAVIP", "OYAVIP") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        (bool success, ) = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}