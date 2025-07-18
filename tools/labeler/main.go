package main

import (
	"context"
	"fmt"
	"os"

	"github.com/google/go-github/v61/github"
	"github.com/hashicorp/go-multierror"
	"golang.org/x/oauth2"
)

type Label struct {
	// Name is the name of the label. It should be lowercase to match our standards.
	Name string

	// Description is the description of the label, with no trailing period.
	Description string

	// Color is the hex color of the label, without the leading "#".
	Color string
}

// DefaultLabels is the authoritative list of labels.
var DefaultLabels = []*Label{
	{"bug", "Something isn't working", "c5221f"},
	{"documentation", "Improvements or additions to documentation", "1967d2"},
	{"enhancement", "New feature or request", "ceead6"},
	{"good first issue", "Good for newcomers", "188038"},
	{"help wanted", "Extra attention is needed", "feefc3"},
}

// IgnoredRepoNames is a list of repository names to skip.
// NOTE: Always ignore release-please-action as they have custom label mapping.
var IgnoredRepoNames = map[string]struct{}{
	"release-please-action": {},
}

func main() {
	ctx := context.Background()

	tokenSource := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv("GITHUB_TOKEN")},
	)

	client := github.NewClient(oauth2.NewClient(ctx, tokenSource))

	repos, _, err := client.Repositories.ListByUser(ctx, "google-github-actions", &github.RepositoryListByUserOptions{
		ListOptions: github.ListOptions{
			PerPage: 100,
		},
	})
	if err != nil {
		panic(err)
	}

	for _, repo := range repos {
		if _, ok := IgnoredRepoNames[*repo.Name]; ok {
			fmt.Printf("ignoring %s...\n", *repo.Name)
			continue
		}

		fmt.Printf("syncing %s...\n", *repo.Name)
		if err := syncLabels(ctx, client, "google-github-actions", *repo.Name); err != nil {
			panic(err)
		}
	}
}

func syncLabels(ctx context.Context, client *github.Client, owner, repo string) error {
	labels, _, err := client.Issues.ListLabels(ctx, owner, repo, &github.ListOptions{PerPage: 50})
	if err != nil {
		return fmt.Errorf("failed to list labels: %w", err)
	}

	labelsCopy := make(map[string]*Label, len(DefaultLabels))
	for _, v := range DefaultLabels {
		labelsCopy[v.Name] = &Label{
			Name:        v.Name,
			Description: v.Description,
			Color:       v.Color,
		}
	}

	toDelete := make([]*github.Label, 0, len(labels))
	toUpdate := make([]*github.Label, 0, len(labels))
	for _, label := range labels {
		v, ok := labelsCopy[*label.Name]
		delete(labelsCopy, *label.Name)

		// An upstream label exists which is not in the allowed set, delete it.
		if !ok {
			toDelete = append(toDelete, label)
			continue
		}

		if *label.Description != v.Description || *label.Color != v.Color {
			label.Description = &v.Description
			label.Color = &v.Color
			toUpdate = append(toUpdate, label)
			continue
		}
	}

	toCreate := make([]*github.Label, 0, len(labelsCopy))
	for _, v := range labelsCopy {
		toCreate = append(toCreate, &github.Label{
			Name:        &v.Name,
			Description: &v.Description,
			Color:       &v.Color,
		})
	}

	var merr *multierror.Error
	for _, v := range toDelete {
		if _, err := client.Issues.DeleteLabel(ctx, owner, repo, *v.Name); err != nil {
			fmt.Printf("deleting label %s\n", *v.Name)
			merr = multierror.Append(merr, fmt.Errorf("failed to delete label %s: %w", *v.Name, err))
		}
	}

	for _, v := range toUpdate {
		if _, _, err := client.Issues.EditLabel(ctx, owner, repo, *v.Name, v); err != nil {
			fmt.Printf("editing label %s\n", *v.Name)
			merr = multierror.Append(merr, fmt.Errorf("failed to edit label %s: %w", *v.Name, err))
		}
	}

	for _, v := range toCreate {
		if _, _, err := client.Issues.CreateLabel(ctx, owner, repo, v); err != nil {
			fmt.Printf("creating label %s\n", *v.Name)
			merr = multierror.Append(merr, fmt.Errorf("failed to create label %s: %w", *v.Name, err))
		}
	}

	return merr.ErrorOrNil()
}
