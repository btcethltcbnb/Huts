pragma solidity ^0.4.24;

 /// @title HutOwnersip, the facet of the dApp that manages ownership, ERC-721 compliant.
 
    import "./HutRegistry.sol";
    import "./ERC721Basic.sol";

    contract HutOwnership  {

    /// Name and symbol of the non fungible token, as defined in ERC721.
    string public name = "MarsTitleDeed";
    string public symbol = "MTD";

    // The contract that will return hut metadata
    ERC721Metadata public erc721Metadata;

    // bool public implementsERC721 = true;
   function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
    // DEBUG ONLY
    //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
    /// @dev Set the address of the sibling contract that tracks metadata.
    ///  Only controled by the address deploying the conytract.
    function setMetadataAddress(address _contractAddress) public onlyOwner {
        erc721Metadata = ERC721Metadata(_contractAddress);
        }
        
    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// Checks if a given address is the current owner of a particular Hut.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId hut id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return hutIndexToOwner[_tokenId] == _claimant;
    }

    /// Checks if a given address currently has transferApproval for a particular hut.
    /// @param _claimant the address we are confirming hut is approved for.
    /// @param _tokenId hut id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return hutIndexToApproved[_tokenId] == _claimant;
    }

    ///  Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting houses on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        hutIndexToApproved[_tokenId] = _approved;
    }

    ///  Transfers a hut owned by this contract to the specified address.
    ///  Used to rescue 'lost' huts. (There is no "proper" flow where this contract
    ///  should be the owner of any hut. This function exists for us to reassign
    ///  the ownership of huts that users may have accidentally sent to our address.)
    /// @param _hutId - ID of hut.
    /// @param _recipient - Address to send the hut to
    function rescueLostHut(uint256 _hutId, address _recipient) public onlyOwner {
        require(_owns(this, _hutId));
        _transfer(this, _recipient, _hutId);
    }

    ///  Returns the number of huts owned by a specific address.
    /// @param _owner The owner address to check.
    /// Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    ///  Transfers a Kitty to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  "MarsTitleDeed" specifically) or your hut may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// To avoid people losing their huts on main platform, this will be required to be an address.
    /// @param _tokenId The ID of the hut to transfer.
    ///  Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // You can only send your own cat.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific hut via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the hut that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    ///  Transfer a hut owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the hut to be transfered.
    /// @param _to The address that should take ownership of the hut. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the hut to be transferred.
    /// Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Kitties currently in existence.
    /// Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return huts.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given hut.
    ///  Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = hutIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns the nth hut assigned to an address, with n specified by the
    ///  _index argument.
    /// @param _owner The owner whose Kitties we are interested in.
    /// @param _index The zero-based index of the huts within the owner's list of huts.
    ///  Must be less than balanceOf(_owner).
    /// @dev This method MUST NEVER be called by smart contract code. It will almost
    ///  certainly blow past the block gas limit once there are a large number of
    ///  huts in existence. Exists only to allow off-chain queries of ownership.
    ///  Optional method for ERC-721.
    function tokensOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (kittyIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }
    
    ///  Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the Kitty whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}
