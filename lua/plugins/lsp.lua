return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        intelephense = {},
        html = {
          filetypes = { 'html', 'htm', 'xhtml', 'php', 'phtml', 'blade', 'twig' },
          settings = {
            html = { suggest = { html5 = true } }
          }
        },
        cssls = {},
        dartls = { enabled = false },
        csharp_ls = { enabled = false },
        omnisharp = { enabled = false },
        roslyn_ls = { filetypes = { 'cs', 'vb', 'csproj', 'sln', 'razor', 'cshtml' },
          filetypes = { 'cs', 'vb', 'csproj', 'sln', 'razor', 'cshtml' }
        }
      }
    }
  }
}
proj', 'sln', 'razor', 'cshtml' }
        }
      }
    }
  }
}
', 'csproj', 'sln', 'razor', 'cshtml' },
          settings = {
            ['csharp|completion'] = {
              dotnet_show_completion_items_from_unimported_namespaces = true
            }
          }
        },
      },
    },
  },
}

}
        },
        },
      },
    },
  },
}
   dotnet_show_completion_items_from_unimported_namespaces = true,
            },
          },
        },
      },
    },
  },
}
