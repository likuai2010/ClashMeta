//go:build !((android || ohos) && cmfa)

package dns

func UpdateIsolateHandler(resolver *Resolver, mapper *ResolverEnhancer) {
}
