//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ByteHasher } from './helpers/ByteHasher.sol';
import { IWorldID } from './interfaces/IWorldID.sol';

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@opengsn/contracts/src/ERC2771Recipient.sol";


contract Contract is ERC2771Recipient, ERC721URIStorage  {

    using ByteHasher for bytes;
    using Counters for Counters.Counter;

    event HorseyVerified(address indexed verifiedAddress, uint256 count);

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @dev The WorldID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The application's action ID
    uint256 internal immutable actionId;

    /// @dev The WorldID group ID (1)
    uint256 internal immutable groupId = 1;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) internal nullifierHashes;


    Counters.Counter private _tokenIds;

    constructor(IWorldID _worldId, string memory _actionId, address _trustedForwarder) ERC721("HorseyTestNFT", "NFT") {
        worldId = _worldId;
        actionId = abi.encodePacked(_actionId).hashToField();
        _setTrustedForwarder(_trustedForwarder);
    }

    function verifyAndMintNFT(address recipient, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) public
        returns (uint256)
    {

        // first, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        // then, we verify they're registered with WorldID, and the recipient they've provided is correct
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(recipient).hashToField(),
            nullifierHash,
            actionId,
            proof
        );
        
        nullifierHashes[nullifierHash] = true;


        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, "ipfs://QmVV5i4n9jBT8L3W5jLfV898wzAn2ah7mGDFmpKHS7UzSJ");


        emit HorseyVerified(recipient, newItemId);


        return newItemId;
    }

    string public versionRecipient = "2.2.0";

    function _msgSender() internal view override(Context, ERC2771Recipient)
        returns (address sender) {
        sender = ERC2771Recipient._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Recipient)
        returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }
}
