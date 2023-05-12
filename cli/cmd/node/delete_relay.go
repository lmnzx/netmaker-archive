package node

import (
	"github.com/gravitl/netmaker/cli/functions"
	"github.com/spf13/cobra"
)

var deleteRelayCmd = &cobra.Command{
	Use:   "delete_relay [NETWORK] [NODE ID]",
	Args:  cobra.ExactArgs(2),
	Short: "Delete Relay from a node",
	Long:  `Delete Relay from a node`,
	Run: func(cmd *cobra.Command, args []string) {
		functions.PrettyPrint(functions.DeleteRelay(args[0], args[1]))
	},
}

func init() {
	rootCmd.AddCommand(deleteRelayCmd)
}
