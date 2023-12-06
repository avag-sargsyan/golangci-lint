package golinters

import (
	"fmt"
	"github.com/golangci/golangci-lint/pkg/config"
	"github.com/golangci/golangci-lint/pkg/golinters/goanalysis"
	"github.com/golangci/golangci-lint/pkg/lint/linter"
	"golang.org/x/mod/modfile"
	"golang.org/x/tools/go/analysis"
	"os"
	"path/filepath"
	"strings"
)

var Analyzer = &analysis.Analyzer{
	Name: "gomodcheck",
	Doc:  "Verifies dependencies in go.mod file against whitelisted ones",
	Run:  nil, // This will be set in New after configuration is parsed
}

//
//type GoModCheckConfig struct {
//	AllowedDependencies []string `mapstructure:"allowed-dep"`
//}

func NewGoModCheck(conf *config.GoModCheckSettings) *goanalysis.Linter {
	var resIssues []goanalysis.Issue

	analyzer := &analysis.Analyzer{
		Name: "gomodcheck",
		Doc:  "Verifies dependencies in go.mod file against whitelisted ones",
		Run: func(pass *analysis.Pass) (any, error) {
			issues := runGoModCheck(pass, conf)

			if len(issues) == 0 {
				return nil, nil
			}

			return nil, nil
		},
	}

	return goanalysis.NewLinter(
		"gomodcheck",
		"Verifies dependencies in go.mod file against whitelisted ones",
		[]*analysis.Analyzer{analyzer},
		nil,
	).WithIssuesReporter(func(*linter.Context) []goanalysis.Issue {
		return resIssues
	}).WithLoadMode(goanalysis.LoadModeSyntax)
}

func runGoModCheck(pass *analysis.Pass, config *config.GoModCheckSettings) []goanalysis.Issue {
	var reports []goanalysis.Issue
	//for _, f := range pass.Files {

	modRoot, err := findModuleRoot()
	if err != nil {
		pass.Reportf(pass.Files[0].Package, "error: %s", err)
		//reports = append(reports, goanalysis.NewIssue(&v.issues[i], pass))
	}

	goModPath := filepath.Join(modRoot, "go.mod")
	data, err := os.ReadFile(goModPath)
	if err != nil {
		pass.Reportf(pass.Files[0].Package, "error: %s", err)
	}

	modFile, err := modfile.Parse("go.mod", data, nil)
	if err != nil {
		pass.Reportf(pass.Files[0].Package, "error: %s", err)
	}

	for _, req := range modFile.Require {
		if req.Indirect {
			continue // Do not verify indirect dependencies
		}
		isAllowed := false
		for _, allowed := range config.AllowedDependencies {
			// This validates all subpackages as well for the given dependency
			// TODO: maybe we need exact match?
			if strings.HasPrefix(req.Mod.Path, allowed) {
				isAllowed = true
				break
			}
		}

		if !isAllowed {
			line := req.Syntax.Start.Line
			pass.Reportf(pass.Files[0].Package, "'%s' is not an allowed dependency in go.mod at line %d", req.Mod.Path, line)
		}
	}

	//}

	return reports

}

func findModuleRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	// Traverse up the directory tree to find the go.mod file
	for {
		_, err := os.Stat(filepath.Join(dir, "go.mod"))
		if err == nil {
			return dir, nil
		}

		// Check if we have reached the root of the filesystem
		if parent := filepath.Dir(dir); parent == dir {
			return "", fmt.Errorf("go.mod not found")
		} else {
			dir = parent
		}
	}
}
