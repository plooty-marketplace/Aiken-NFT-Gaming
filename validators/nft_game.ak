use cardano/transaction.{OutputReference, Transaction}
use cardano/assets.{PolicyId}
use value

// Define an action type for minting and burning operations
type Action {
  CheckMint
  CheckBurn
}

validator nft_game(token_name: ByteArray, utxo_ref: OutputReference) {

  spend(_d: Data, _r: Data, _o: Data, tx: Transaction) -> Bool {
    spend_nft(token_name, utxo_ref, tx)
  }

  mint(rdmr: Action, policy_id: PolicyId, tx: Transaction) -> Bool {
    mint_nft(rdmr, token_name, policy_id, utxo_ref, tx)
  }
}

// Helper function for minting logic
mint_nft(rdmr: Action, token_name: ByteArray, policy_id: PolicyId, utxo_ref: OutputReference, tx: Transaction) -> Bool {
  let Transaction { inputs, mint, .. } = tx

  expect [Pair(asset_name, amount)] = 
    mint |> value.from_minted_value |> value.tokens(policy_id) |> dict.to_pairs()

  match rdmr {
    CheckMint -> {
      // Check if input with matching OutputReference exists and asset name/amount are correct
      expect Some(_input) = list.find(inputs, fn(input) { input.output_reference == utxo_ref })
      amount == 1 && asset_name == token_name
    }
    CheckBurn -> 
      amount == -1 && asset_name == token_name
  }
}

// Helper function for spend logic
spend_nft(token_name: ByteArray, own_ref: OutputReference, tx: Transaction) -> Bool {
  let Transaction { mint, inputs, .. } = tx

  expect Some(own_input) = list.find(inputs, fn(input) { input.output_reference == own_ref })
  expect Script(policy_id) = own_input.output.address.payment_credential

  expect [Pair(asset_name, amount)] = 
    mint |> value.from_minted_value |> value.tokens(policy_id) |> dict.to_pairs()

  amount == -1 && asset_name == token_name
}
